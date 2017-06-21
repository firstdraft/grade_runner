namespace :grade_runner do
  desc "Grade project"
  task runner: :environment do
    config_file_name = Rails.root.join(".firstdraft_project.yml")
    config = YAML.load_file(config_file_name)
    GradeRunner::Runner.new(config['project_token'], config['submission_url'], ENV['GRADES_PERSONAL_ACCESS_TOKEN']).process
  end
end

