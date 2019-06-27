require 'yaml'
require 'net/http'
require "json"

desc "Alias for \"grade:next\"."
task grade: "grade:all" do
end

namespace :grade do
  desc "Run all tests and submit a build report."
  task :all do
    ARGV.each { |a| task a.to_sym do ; end }
    input_token = ARGV[1]
    file_token = nil

    config_file_name = File.join(__dir__, "grades.yml")
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

    if input_token != false &&
       input_token != "" &&
       input_token !=  " " && 
       !input_token.nil? && 
       input_token != [] && 
       input_token != {}

      token = input_token
      student_config["personal_access_token"] = input_token
      update_config_file(config_file_name, student_config)
    elsif input_token.nil? &&
      file_token != false &&
      file_token != "" &&
      file_token !=  " " && 
      !file_token.nil? && 
      file_token != [] && 
      file_token != {}

      token = file_token
    elsif input_token.nil? && file_token.nil?
      puts "Enter your access token for this project"
      new_personal_access_token = ""

      while new_personal_access_token == "" do
        print "> "
        new_personal_access_token = $stdin.gets.chomp.strip

        if new_personal_access_token!= "" && is_valid_token?(submission_url, new_personal_access_token) == false
          p "You entered: #{new_personal_access_token}"
          p submission_url
          p "---"
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
    
    if token != false &&
      token != "" &&
      token !=  " " && 
      !token.nil? && 
      token != [] && 
      token != {}
      if is_valid_token?(submission_url, token) == false
        student_config["personal_access_token"] = nil
        update_config_file(config_file_name, student_config)
        puts "Your access token looked invalid, so we've reset it to be blank. Please re-run rake grade and, when asked, copy-paste your token carefully from the assignment page."
      else
        path = File.join(__dir__, "/tmp/output/#{Time.now.to_i}.json")
        # `bin/rails db:migrate RAILS_ENV=test`
        if Dir.exist?("bin")
          `bin/rake db:migrate`
        end
        # `RAILS_ENV=test bundle exec rspec --order default --format JsonOutputFormatter --out #{path}`
        `bundle exec rspec --order default --format JsonOutputFormatter --out #{path}`
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
  return false unless token.is_a?(String) && !(token =~ /^[1-9A-Za-z][^OIl]{23}$/).nil?
  p "remove me later"
  p token.is_a?(String) && !(token =~ /^[1-9A-Za-z][^OIl]{23}$/).nil?
  p root_url
  url = "#{root_url}/submissions/validate_token?token=#{token}"
  p url
  p "url: #{url}"
  uri = URI.parse(url)
  p "uri: #{uri.to_s}"
  p uri.hostname
  p uri.port
  req = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
  p req
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    p "net"
    p http
    p req
    http.request(req)
  end
  p "done with request "
  result = JSON.parse(res.body)
  p "Result: "
  p result
  result["success"]
rescue => e
  p "error!"
  p e
  return false
end
