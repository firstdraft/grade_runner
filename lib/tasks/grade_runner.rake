namespace :grade_runner do
  desc "Grade project"
  task runner: :environment do
    config_file_name = Rails.root.join(".firstdraft_project.yml")
    config = YAML.load_file(config_file_name)
    rspec_output_json = JSON.parse(File.read("#{ENV['CIRCLE_ARTIFACTS']}/output/rspec_output.json"))
    username = ENV["CIRCLE_PROJECT_USERNAME"]
    reponame = ENV["CIRCLE_PROJECT_REPONAME"]
    sha = ENV["CIRCLE_SHA1"]
    token = ENV['GRADES_PERSONAL_ACCESS_TOKEN']
    if token.present?
      GradeRunner::Runner.new(config['project_token'], config['submission_url'], token, rspec_output_json, username, reponame, sha, 'circle_ci').process
    else
      puts "Please launch assignment from canvas and run rails grade manually as show in launch page from canvas"
    end
  end
end
