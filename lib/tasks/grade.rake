require "active_support/core_ext/object/blank"
require "grade_runner/runner"
require "octokit"
require "yaml"
require "zip"
require "fileutils"
require "open-uri"

desc "Alias for \"grade:next\"."
task grade: "grade:all" do
end

namespace :grade do
  desc "Run all tests and submit a build report."
  task :all do
    ARGV.each { |a| task a.to_sym do ; end }
    input_token = ARGV[1]
    file_token = nil

    config_dir_name = find_or_create_directory(".vscode")
    config_file_name = "#{config_dir_name}/.ltici_apitoken.yml"
    student_config = {}
    student_config["submission_url"] = "https://grades.firstdraft.com"

    if File.exist?(config_file_name)
      begin
        config = YAML.load_file(config_file_name)
      rescue
        abort "It looks like there's something wrong with your token in `#{config_dir_name}/.ltici_apitoken.yml`. Please delete that file and try `rails grade` again, and be sure to provide the access token for THIS project.".red
      end
      submission_url = config["submission_url"]
      file_token = config["personal_access_token"]
      student_config["submission_url"] = config["submission_url"]
    else
      submission_url = "https://grades.firstdraft.com"
    end
    if file_token.nil? && ENV.has_key?("LTICI_GITPOD_APITOKEN")
      input_token = ENV.fetch("LTICI_GITPOD_APITOKEN")
    end
    if input_token.present?
      token = input_token
      student_config["personal_access_token"] = input_token
      update_config_file(config_file_name, student_config)
    elsif input_token.nil? && file_token.present?
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
    
    if token.present? 

      if is_valid_token?(submission_url, token) == false
        student_config["personal_access_token"] = nil
        update_config_file(config_file_name, student_config)
        puts "Your access token looked invalid, so we've reset it to be blank. Please re-run rails grade and, when asked, copy-paste your token carefully from the assignment page."
      else 
        resource_info = upstream_repo(submission_url, token)
        full_reponame = resource_info.fetch("repo_slug")
        remote_spec_folder_sha = resource_info.fetch("spec_folder_sha")
        source_code_url = resource_info.fetch("source_code_url")
        set_upstream_remote(full_reponame)
        sync_specs_with_source(full_reponame, remote_spec_folder_sha, source_code_url)

        path = File.join(project_root, "/tmp/output/#{Time.now.to_i}.json")
        `bin/rails db:migrate RAILS_ENV=test` if defined?(Rails)
        `RAILS_ENV=test bundle exec rspec --format JsonOutputFormatter --out #{path}`
        rspec_output_json = Oj.load(File.read(path))
        username = retrieve_github_username
        reponame = project_root.to_s.split("/").last
        sha = `git rev-parse HEAD`.slice(0..7)

        GradeRunner::Runner.new(submission_url, token, rspec_output_json, username, reponame, sha, "manual").process
      end
    else
      puts "We couldn't find your access token, so we couldn't record your grade. Please click on the assignment link again and run the rails grade ...  command shown there."
    end
  end

  desc "Run only the next failing test."
  task :next do
    path = File.join(project_root, "examples.txt")
    if File.exist?(path)
      `bin/rails db:migrate RAILS_ENV=test` if defined?(Rails)
      puts `RAILS_ENV=test bundle exec rspec --next-failure --format HintFormatter`
    else
      puts `RAILS_ENV=test bundle exec rspec`
      puts "Please rerun rails grade:next to run the first failing spec"
    end
  end

  desc "Reset access token saved in YAML file."
  task :reset_token do
    config_dir_name = find_or_create_directory(".vscode")
    config_file_name = "#{config_dir_name}/.ltici_apitoken.yml"
    submission_url = "https://grades.firstdraft.com"

    student_config = {}
    student_config["submission_url"] = submission_url
    puts "Enter your access token for this project"
    new_personal_access_token = ""

    while new_personal_access_token == "" do
      print "> "
      new_personal_access_token = $stdin.gets.chomp.strip
      token_valid = is_valid_token?(submission_url, new_personal_access_token)
      unless token_valid && !new_personal_access_token.empty?
        puts "Please enter valid token"
        new_personal_access_token = ""
      end

      unless new_personal_access_token.empty?
        student_config["personal_access_token"] = new_personal_access_token
        student_config["github_username"] = retrieve_github_username
        update_config_file(config_file_name, student_config)
        token = new_personal_access_token
      end
    end
    puts "Grade token has been reset successfully."
  end

end

def sync_specs_with_source(full_reponame, remote_sha, repo_url)
  # Unstage staged changes in spec folder
  `git restore --staged spec/* `
  # Discard unstaged changes in spec folder
  `git checkout spec -q`
  `git clean spec -f -q`
  local_sha = `git ls-tree HEAD #{project_root.join('spec')}`.chomp.split[2]

  unless remote_sha == local_sha
    files_and_subfolders_inside_specs = Dir.glob("spec/*")
    # Remove the contents of the directory
    FileUtils.rm_rf(files_and_subfolders_inside_specs)

    find_or_create_directory("tmp")
    download_file(repo_url, "tmp/spec.zip")
    extracted_zip_folder = extract_zip("tmp/spec.zip", "tmp")
    source_directory = extracted_zip_folder.join("spec")
    overwrite_spec_folder(source_directory)

    FileUtils.rm(project_root.join("tmp/spec.zip"))
    FileUtils.rm_rf(extracted_zip_folder)
    `git add spec/`
    `git commit spec/ -m "Update spec/ folder to latest version" --author "First Draft <grades@firstdraft.com>"`
  end
end

def download_file(url, destination)
  download = URI.open(url)
  IO.copy_stream(download, destination)
end

def extract_zip(folder, destination)
  extracted_file_path = project_root.join(destination)
  Zip::File.open(folder) do |zip_file|
    zip_file.each_with_index do |file, index|
      # Get name of root folder in zip file
      if index == 0
        extracted_file_path = extracted_file_path.join(file.name)
      end
      file_path = File.join(destination, file.name)
      FileUtils.mkdir_p(File.dirname(file_path))
      file.extract(file_path)
    end
  end
  extracted_file_path
end

def overwrite_spec_folder(source_directory)
  destination_directory = "spec"
  # Get all files in the source directory
  files = Dir.glob("#{source_directory}/*")
  # Move each file to the destination directory
  files.each do |file|
    FileUtils.mv(file, destination_directory)
  end
end

def set_upstream_remote(repo_slug)
  upstream = `git remote -v | grep -w upstream`.chomp
  if upstream.blank?
    `git remote add upstream https://github.com/#{repo_slug}`
  else
    `git remote set-url upstream https://github.com/#{repo_slug}`
  end
end

def update_config_file(config_file_name, config)
  File.write(config_file_name, YAML.dump(config))
end

def find_or_create_directory(directory_name)
  directory = File.join(project_root, directory_name)
  Dir.mkdir(directory) unless Dir.exist?(directory)
  directory
end

def is_valid_token?(root_url, token)
  return false unless token.is_a?(String) && token =~ /^[1-9A-Za-z][^OIl]{23}$/
  url = "#{root_url}/submissions/validate_token?token=#{token}"
  uri = URI.parse(url)
  req = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end
  result = Oj.load(res.body)
  result["success"]
rescue => e
  return false
end

def upstream_repo(root_url, token)
  return false unless token.is_a?(String) && token =~ /^[1-9A-Za-z][^OIl]{23}$/
  url = "#{root_url}/submissions/resource?token=#{token}"
  uri = URI.parse(url)
  req = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end
  Oj.load(res.body)
rescue => e
  return false
end

def retrieve_github_username
  config_dir_name = find_or_create_directory(".vscode")
  config_file_name = "#{config_dir_name}/.ltici_apitoken.yml"
  if File.exist?(config_file_name)
    puts "retrieving from f ile"
    config = YAML.load_file(config_file_name)
    if config["github_username"].present?
      return config["github_username"]
    end
  else
    puts "searching w/ octokit.."
    github_email = `git config user.email`.chomp
    return "" if github_email.blank?
    username = `git config user.name`.chomp
    search_results = Octokit.search_users("#{github_email} in:email").fetch(:items)
    if search_results.present?
      username = search_results.first.fetch(:login, username)
    end
    return username
  end
end

def project_root
  if defined?(Rails)
    return Rails.root
  end

  if defined?(Bundler)
    return Bundler.root
  end
  Dir.pwd
end
