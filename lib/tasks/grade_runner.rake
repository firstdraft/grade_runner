namespace :grade_runner do
  desc "Grade project"
  task runner: :environment do
    config_file_name = Rails.root.join(".firstdraft_project.yml")
    config = YAML.load_file(config_file_name)
    rspec_output_json = File.read("#{ENV['CIRCLE_ARTIFACTS']}/output/rspec_output.json")
    username = ENV["CIRCLE_PROJECT_USERNAME"]
    reponame = ENV["CIRCLE_PROJECT_REPONAME"]
    sha = ENV["CIRCLE_SHA1"]
    GradeRunner::Runner.new(config['project_token'], config['submission_url'], ENV['GRADES_PERSONAL_ACCESS_TOKEN'], rspec_output_json, username, reponame, sha).process
  end
end
