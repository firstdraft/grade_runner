require "yaml"
require "fileutils"
require "grade_runner/utils/path_utils"

module GradeRunner
  module Services
    class ConfigService
      def initialize
        @path_utils = GradeRunner::Utils::PathUtils
      end

      def find_or_create_directory(directory_name)
        @path_utils.find_or_create_directory(directory_name)
      end

      def update_config_file(config_file_name, config)
        File.write(config_file_name, YAML.dump(config))
      end

      def load_config(config_file_name, default_submission_url)
        if File.exist?(config_file_name)
          begin
            YAML.load_file(config_file_name)
          rescue
            abort "It looks like there's something wrong with your token in `#{config_file_name}`. Please delete that file and try `rails grade` again, and be sure to provide the access token for THIS project.".red
          end
        else
          { "submission_url" => default_submission_url }
        end
      end

      def get_config_file_path(directory = ".vscode", filename = ".ltici_apitoken.yml")
        config_dir = find_or_create_directory(directory)
        "#{config_dir}/#{filename}"
      end

      def save_token_to_config(config_file_name, token, submission_url, github_username)
        config = {
          "submission_url" => submission_url,
          "personal_access_token" => token,
          "github_username" => github_username
        }
        update_config_file(config_file_name, config)
      end

      def clear_token_in_config(config_file_name)
        if File.exist?(config_file_name)
          config = YAML.load_file(config_file_name)
          config["personal_access_token"] = nil
          update_config_file(config_file_name, config)
        end
      end
    end
  end
end
