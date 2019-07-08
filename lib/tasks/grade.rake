require 'yaml'
require 'net/http'
require "json"
require_relative "../grade_runner/runner"

desc "Alias for \"grade:next\"."
task grade: "grade:all" do
end

namespace :grade do
  desc "Run all tests and submit a build report."
  task :all do
    ARGV.each { |a| task a.to_sym do ; end }
    input_token = ARGV[1]
    file_token = nil

    config_file_name = File.join(project_root, "grades.yml")
    student_config = {}
    student_config["submission_url"] = "https://grades.firstdraft.com"

    if File.file?(config_file_name)
      begin
        config = YAML.load_file(config_file_name)
      rescue
        abort "It looks like there's something wrong with your token in `/grades.yml`. Please delete that file and try `rake grade:all` again, and be sure to provide the access token for THIS project.".red
      end
      submission_url = config["submission_url"]
      file_token = config["personal_access_token"]
      student_config["submission_url"] = config["submission_url"]
    else
      submission_url = "https://grades.firstdraft.com"
    end

    if !input_token.nil?
      token = input_token
      student_config["personal_access_token"] = input_token
      update_config_file(config_file_name, student_config)
    elsif input_token.nil? && !file_token.nil?
      token = file_token
    elsif input_token.nil? && file_token.nil?
      puts "Enter your access token for this project"
      new_personal_access_token = ""

      while new_personal_access_token == "" do
        print "> "
        new_personal_access_token = $stdin.gets.chomp.strip

        if new_personal_access_token!= "" && is_valid_token?(submission_url, new_personal_access_token) == false
          puts "Please enter valid token"
          new_personal_access_token = ""
        end

        if new_personal_access_token != ""
          student_config["personal_access_token"] = new_personal_access_token
          update_config_file(config_file_name, student_config)
          token = new_personal_access_token
        end
      end
    end
    
    if !token.nil?
      if is_valid_token?(submission_url, token) == false
        student_config["personal_access_token"] = nil
        update_config_file(config_file_name, student_config)
        puts "Your access token looked invalid, so we've reset it to be blank. Please re-run rake grade and, when asked, copy-paste your token carefully from the assignment page."
      else
        path = File.join(project_root, "/tmp/output/#{Time.now.to_i}.json")
        # `bin/rails db:migrate RAILS_ENV=test`
        if Dir.exist?("bin")
          `bin/rake db:migrate`
        end
        # `RAILS_ENV=test bundle exec rspec --order default --format JsonOutputFormatter --out #{path}`
        `bundle exec rspec -I spec/support -f JsonOutputFormatter --out #{path}`
        rspec_output_json = JSON.parse(File.read(path))
        username = ""
        reponame = ""
        sha = ""

        GradeRunner::Runner.new(submission_url, token, rspec_output_json, username, reponame, sha, "manual").process
      end
    else
      puts "We couldn't find your access token, so we couldn't record your grade. Please click on the assignment link again and run the rake grade ...  command shown there."
    end
  end

  desc "Run only the next failing test."
  task :next do
    path = File.join(__dir__, "examples.txt")
    if File.file?(path)
      # `bin/rails db:migrate RAILS_ENV=test`
      # puts `RAILS_ENV=test bundle exec rspec --next-failure --format HintFormatter`
      puts `bundle exec rspec --next-failure --format HintFormatter`
    else
      # puts `RAILS_ENV=test bundle exec rspec`
      puts `bundle exec rspec`
      puts "Please rerun rake grade:next to run the first failing spec"
    end
  end

end

def update_config_file(config_file_name, config)
  File.write(config_file_name, YAML.dump(config))
end

def is_valid_token?(root_url, token)
  return false unless token.is_a?(String) && token =~ /^[1-9A-Za-z][^OIl]{23}$/
  url = "#{root_url}/submissions/validate_token?token=#{token}"
  uri = URI.parse(url)
  req = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end
  result = JSON.parse(res.body)
  result["success"]
rescue => e
  return false
end

def project_root
  # if defined?(Rails)
  #   return Rails.root
  # end

  # if defined?(Bundler)
  #   return Bundler.root
  # end

  Dir.pwd
end