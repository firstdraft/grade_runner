require 'optparse'

desc "Grade"
task grade: "grade:next" do
end

namespace :grade do
  desc "Grade All"
  task all: :environment do
    ARGV.each { |a| task a.to_sym do ; end }
    token = ARGV[1]
    
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
    else
      puts "We couldn't find your access token, so we couldn't record your grade. Please click on the assignment link again and run the rails grade ...  command shown there."
    end
  end

  desc "Grade Next"
  task next: :environment do
    path = Rails.root + "examples.txt"
    if File.exist?(path)
      puts `RAILS_ENV=test bundle exec rspec --next-failure`
    else
      puts `RAILS_ENV=test bundle exec rspec`
      puts "Please rerun rails grade:next to run the first failing spec"
    end
  end

end
