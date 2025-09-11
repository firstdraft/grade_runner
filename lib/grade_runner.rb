require "grade_runner/runner"
require "grade_runner/utils/path_utils"
require "grade_runner/services/token_service"
require "grade_runner/services/config_service"
require "grade_runner/services/github_service"
require "grade_runner/services/spec_service"
require "grade_runner/services/grade_service"
require "grade_runner/railtie" if defined?(Rails)

module GradeRunner
  class Error < StandardError; end

  DEFAULT_SUBMISSION_URL = "https://grades.firstdraft.com"

  class << self
    attr_writer :default_points, :override_local_specs, :submission_url

    def default_points
      @default_points || 1
    end

    def override_local_specs
      if @override_local_specs.nil?
        true
      else
        @override_local_specs
      end
    end

    def submission_url
      @submission_url || DEFAULT_SUBMISSION_URL
    end

    def config
      yield self
    end

    def project_root
      Utils::PathUtils.project_root
    end
  end
end
