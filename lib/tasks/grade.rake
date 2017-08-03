desc "Grade project"
task :grade, :token do |t, args|
  token = args[:token]
  path = Rails.root + "/tmp/output" + "#{SecureRandom.hex}.json"
  `RAILS_ENV=test bundle exec rspec --order default --format JsonOutputFormatter --out #{path}`
  rspec_output_json = JSON.parse(File.read(path))
  config_file_name = Rails.root.join(".firstdraft_project.yml")
  config = YAML.load_file(config_file_name)
  git_url = `git config --get remote.origin.url`.chomp
  username = git_url.split(':')[1].split('/')[0]
  reponame =  git_url.split(':')[1].split('/')[1].sub(".git", "")
  sha = `git rev-parse --verify HEAD`.chomp
  if token.present?
    GradeRunner::Runner.new(config['project_token'], config['submission_url'], token, rspec_output_json, username, reponame, sha, 'manual').process
  end
end
