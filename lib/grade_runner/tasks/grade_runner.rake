require "grade_runner/services/grade_service"
require "grade_runner/utils/path_utils"
require "grade_runner/formatters/json_output_formatter"
require "grade_runner/formatters/hint_formatter"

namespace :grade_runner do
  desc "Grade project"
  task :runner do
    # Handle CI-specific paths and environment
    rspec_output_json = JSON.parse(File.read("#{ENV['CIRCLE_ARTIFACTS']}/output/rspec_output.json"))
    username = ENV["CIRCLE_PROJECT_USERNAME"]
    reponame = ENV["CIRCLE_PROJECT_REPONAME"]
    sha = ENV["CIRCLE_SHA1"]
    token = ENV['GRADES_PERSONAL_ACCESS_TOKEN']

    if token.present?
      # If in CI environment, use Runner directly with CI parameters
      submission_url = GradeRunner.submission_url
      GradeRunner::Runner.new(submission_url, token, rspec_output_json, username, reponame, sha, 'circle_ci').process
    else
      puts "We couldn't find your access token, so we couldn't record your grade. Please click on the assignment link again and run the rails grade ...  command shown there."
    end
  end
end
