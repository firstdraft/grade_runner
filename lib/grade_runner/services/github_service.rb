require "octokit"
require "grade_runner/utils/path_utils"

module GradeRunner
  module Services
    class GithubService
      def initialize
        @path_utils = GradeRunner::Utils::PathUtils
      end

      def retrieve_github_username(config_file_name)
        if File.exist?(config_file_name)
          config = YAML.load_file(config_file_name)
          return config["github_username"] if config["github_username"].present?
        end

        github_email = `git config user.email`.chomp
        return "" if github_email.blank?

        username = `git config user.name`.chomp
        search_results = Octokit.search_users("#{github_email} in:email").fetch(:items)

        if search_results.present?
          username = search_results.first.fetch(:login, username)
        end

        username
      end

      def set_upstream_remote(repo_slug)
        upstream = `git remote -v | grep -w upstream`.chomp
        if upstream.blank?
          `git remote add upstream https://github.com/#{repo_slug}`
        else
          `git remote set-url upstream https://github.com/#{repo_slug}`
        end
      end

      def get_commit_sha
        `git rev-parse HEAD`.slice(0..7)
      end

      def get_repo_name
        # Extract the repository name from the project path
        @path_utils.project_root.to_s.split("/").last
      end
    end
  end
end
