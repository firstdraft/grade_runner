require "active_support/core_ext/object/blank"

module GradeRunner
  module Services
    class GradeService
      def initialize
        @submission_url = GradeRunner.submission_url
        @config_service = ConfigService.new
        @token_service = TokenService.new(@submission_url)
        @github_service = GithubService.new
        @spec_service = SpecService.new
      end

      def process_grade_all(input_token = nil)
        config_file_name = @config_service.get_config_file_path
        config = @config_service.load_config(config_file_name, @submission_url)

        file_token = config["personal_access_token"]

        # Check for Gitpod environment token
        if file_token.nil? && ENV.has_key?("LTICI_GITPOD_APITOKEN")
          input_token = ENV.fetch("LTICI_GITPOD_APITOKEN")
        end

        # Get token (from input, file, or prompt)
        token = @token_service.get_token(input_token, file_token, config_file_name)
        github_username = @github_service.retrieve_github_username(config_file_name)

        # Save token to config if new
        if input_token.present? || (token.present? && file_token.nil?)
          @config_service.save_token_to_config(config_file_name, token, @submission_url, github_username)
        end

        return "We couldn't find your access token. Please click on the assignment link and run the rails grade command shown there." if token.blank?

        # Validate token
        if !@token_service.validate_token(token)
          @config_service.clear_token_in_config(config_file_name)
          return "Your access token looked invalid, so we've reset it to be blank. Please re-run rails grade and copy-paste your token carefully from the assignment page."
        end

        # Sync specs if needed
        if GradeRunner.override_local_specs
          resource_info = @token_service.fetch_upstream_repo(token)
          full_reponame = resource_info.fetch("repo_slug")
          remote_spec_folder_sha = resource_info.fetch("spec_folder_sha")
          source_code_url = resource_info.fetch("source_code_url")

          @github_service.set_upstream_remote(full_reponame)
          @spec_service.sync_specs_with_source(full_reponame, remote_spec_folder_sha, source_code_url)
        end

        # Run tests
        output_path = @spec_service.prepare_output_directory
        rspec_output_json = @spec_service.run_tests(output_path)

        # Submit results
        username = github_username
        reponame = @github_service.get_repo_name
        sha = @github_service.get_commit_sha

        GradeRunner::Runner.new(@submission_url, token, rspec_output_json, username, reponame, sha, "manual").process

        "Grade submitted successfully"
      end

      def process_reset_token
        config_file_name = @config_service.get_config_file_path
        github_username = @github_service.retrieve_github_username(config_file_name)

        # Get new token from user
        token = @token_service.prompt_for_token(config_file_name)

        # Save token
        @config_service.save_token_to_config(config_file_name, token, @submission_url, github_username)

        "Grade token has been reset successfully."
      end
    end
  end
end
