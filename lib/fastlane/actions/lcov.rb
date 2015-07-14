module Fastlane
  module Actions
    class LcovAction < Action

      def self.is_supported?(platform)
        [:ios, :mac].include? platform
      end

      def self.run(options)
        unless Helper.test?
          raise 'lcov not installed, please install using `brew install lcov`'.red if `which lcov`.length == 0
        end
        gen_cov(options)
      end

      def self.description
        "Generates coverage data using lcov"
      end

      def self.available_options
        [

          FastlaneCore::ConfigItem.new(key: :project_name,
                                       env_name: "FL_LCOV_PROJECT_NAME",
                                       description: "Name of the project"),

          FastlaneCore::ConfigItem.new(key: :scheme,
                                       env_name: "FL_LCOV_SCHEME",
                                       description: "Scheme of the project"),

          FastlaneCore::ConfigItem.new(key: :configuration,
                                       env_name: "FL_LCOV_CONFIGURATION",
                                       description: "Configuration of the project",
                                       optional: true,
                                       is_string: true,
                                       default_value: "Debug"),

          FastlaneCore::ConfigItem.new(key: :output_dir,
                                       env_name: "FL_LCOV_OUTPUT_DIR",
                                       description: "The output directory that coverage data will be stored. If not passed will use coverage_reports as default value",
                                       optional: true,
                                       is_string: true,
                                       default_value: "coverage_reports"),

          FastlaneCore::ConfigItem.new(key: :build_dir,
                                       env_name: "FL_LCOV_BUILD_DIR",
                                       description: "The build directory where lcov should look for the Derived Data",
                                       optional: true,
                                       is_string: true)

        ]
      end

      def self.author
        "thiagolioy"
      end

      private

        def self.gen_cov(options)
          output_dir = options[:output_dir]
          tmp_cov_file = "#{output_dir}/coverage.info"
          derived_data_path = derived_data_dir(options)

          system("lcov --capture --directory \"#{derived_data_path}\" --output-file #{tmp_cov_file} --rc lcov_branch_coverage=1")
          system(gen_lcov_cmd(tmp_cov_file))
          system("genhtml #{tmp_cov_file} --output-directory #{output_dir} --branch-coverage --rc genhtml_branch_coverage=1")
        end

        def self.gen_lcov_cmd(cov_file)
          cmd = "lcov "
          exclude_dirs.each do |e|
            cmd << "--rc lcov_branch_coverage=1 --remove #{cov_file} \"#{e}\" "
          end
          cmd << "--rc lcov_branch_coverage=1 --output #{cov_file} "
        end

        def self.derived_data_dir(options)
          build_dir = options[:build_dir]

          if build_dir.to_s == ''
            pn = options[:project_name]
            sc = options[:scheme]
            cf = options[:configuration]

            initial_path = "#{Dir.home}/Library/Developer/Xcode/DerivedData/"
            end_path = "/Build/Intermediates/#{pn}.build/#{cf}-iphonesimulator/#{sc}.build/Objects-normal/x86_64/"

            match = find_project_dir(pn,initial_path)

            build_dir = "#{initial_path}#{match}#{end_path}"
          end

          "#{build_dir}"
        end

        def self.find_project_dir(project_name,path)
          `ls -t #{path}| grep #{project_name} | head -1`.to_s.gsub(/\n/, "")
        end

        def self.exclude_dirs
          ["/Applications/*","/Frameworks/*","*/*Tests*/*"]
        end

    end
  end
end
