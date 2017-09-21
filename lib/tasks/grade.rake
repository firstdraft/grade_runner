desc "Alias for \"grade:next\"."
task grade: "grade:next" do
end

namespace :grade do
  desc "Run all tests and submit a build report."
  task all: :environment do
    ARGV.each { |a| task a.to_sym do ; end }
    token = ARGV[1]
    
    path = Rails.root.join("/tmp/output/#{Time.now.to_i}.json")
    `RAILS_ENV=test bundle exec rspec --order default --format JsonOutputFormatter --out #{path}`

    rspec_output_json = JSON.parse(File.read(path))
    config_file_name = Rails.root.join(".firstdraft_project.yml")
    
    if File.exist?(config_file_name)
      config = YAML.load_file(config_file_name)
      submission_url, project_token = config["submission_url"], config["project_token"]
    else
      submission_url, project_token = "https://grades.firstdraft.com/builds", ''
    end

    git_url = `git config --get remote.origin.url`.chomp
    username = git_url.split(':')[1].split('/')[0]
    reponame =  git_url.split(':')[1].split('/')[1].sub(".git", "")
    sha = `git rev-parse --verify HEAD`.chomp

    if token.present?
      GradeRunner::Runner.new(project_token, submission_url, token, rspec_output_json, username, reponame, sha, "manual").process
    else
      puts "We couldn't find your access token, so we couldn't record your grade. Please click on the assignment link again and run the rails grade ...  command shown there."
    end
  end

  desc "Run only the next failing test."
  task next: :environment do
    path = Rails.root.join("examples.txt")
    if File.exist?(path)
      puts `RAILS_ENV=test bundle exec rspec --next-failure`
    else
      puts `RAILS_ENV=test bundle exec rspec`
      puts "Please rerun rails grade:next to run the first failing spec"
    end
  end

end
