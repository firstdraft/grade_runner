require "oj"
require "fileutils"
require "grade_runner/utils/path_utils"
require "active_support/core_ext/object/blank"
require "open-uri"
require "zip"

module GradeRunner
  module Services
    class SpecService
      def initialize
        @path_utils = GradeRunner::Utils::PathUtils
      end

      def run_tests(output_path)
        # Ensure database is migrated if Rails app
        `bin/rails db:migrate RAILS_ENV=test` if defined?(Rails)

        # Run tests with JSON formatter and explicitly set path to specs
        project_root = Dir.pwd
        spec_dir     = File.join(project_root, "spec")
        args = [
          "--default-path", spec_dir,
          "--pattern", "**/*_spec.rb",
          "--format", "JsonOutputFormatter",
          "--out", output_path, # "tmp/output/results.json"
          spec_dir
        ]

        # Run RSpec via its Ruby API so you stay in the same process
        # This helps with using JsonOutputFormatter
        # TODO: handle non-zero exit code
        RSpec::Core::Runner.run(args)

        # Load and return test results
        Oj.load(File.read(output_path))
      end

      def sync_specs_with_source(full_reponame, remote_sha, repo_url)
        # Return if required parameters are missing
        return false unless full_reponame && remote_sha && repo_url

        # Unstage staged changes in spec folder
        `git restore --staged spec/* 2>/dev/null`
        # Discard unstaged changes in spec folder
        `git checkout spec -q 2>/dev/null`
        `git clean spec -f -q 2>/dev/null`

        # Get local SHA of spec folder
        local_sha_output = `git ls-tree HEAD #{@path_utils.project_root}/spec 2>/dev/null`.chomp
        local_sha = local_sha_output.split[2] if local_sha_output.present?

        # Only update if remote SHA differs from local SHA
        unless remote_sha == local_sha
          # Create temporary directories
          tmp_dir = @path_utils.find_or_create_directory("tmp")
          backup_dir = @path_utils.find_or_create_directory("tmp/backup")

          # Backup existing specs if they exist
          if Dir.exist?("#{@path_utils.project_root}/spec")
            files_and_subfolders = Dir.glob("#{@path_utils.project_root}/spec/*")
            FileUtils.mv(files_and_subfolders, backup_dir) if files_and_subfolders.any?
          else
            FileUtils.mkdir_p("#{@path_utils.project_root}/spec")
          end

          # Download spec zip file
          zip_path = "#{tmp_dir}/spec.zip"
          download_file(repo_url, zip_path)

          # Extract zip file
          extracted_folder = extract_zip(zip_path, tmp_dir)
          source_directory = File.join(extracted_folder, "spec")

          # Overwrite spec folder with new specs
          overwrite_spec_folder(source_directory)

          # Clean up
          FileUtils.rm(zip_path) if File.exist?(zip_path)
          FileUtils.rm_rf(extracted_folder) if extracted_folder && Dir.exist?(extracted_folder)
          FileUtils.rm_rf(backup_dir) if Dir.exist?(backup_dir)

          # Commit changes
          `git add spec/ 2>/dev/null`
          `git commit spec/ -m "Update spec/ folder to latest version" --author "First Draft <grades@firstdraft.com>" 2>/dev/null`

          return true
        end

        false
      rescue => e
        # In case of error, still try to clean up
        tmp_zip = "#{@path_utils.tmp_path}/spec.zip"
        FileUtils.rm(tmp_zip) if File.exist?(tmp_zip)
        FileUtils.rm_rf("#{@path_utils.tmp_path}/backup") if Dir.exist?("#{@path_utils.tmp_path}/backup")
        false
      end

      def download_file(url, destination)
        download = URI.open(url)
        IO.copy_stream(download, destination)
      end

      def extract_zip(folder, destination)
        extracted_file_path = destination

        Zip::File.open(folder) do |zip_file|
          zip_file.each_with_index do |file, index|
            # Get name of root folder in zip file
            if index == 0
              extracted_file_path = File.join(destination, file.name)
            end

            file_path = File.join(destination, file.name)
            FileUtils.mkdir_p(File.dirname(file_path))
            file.extract(file_path) unless File.exist?(file_path)
          end
        end

        extracted_file_path
      end

      def overwrite_spec_folder(source_directory)
        destination_directory = "#{@path_utils.project_root}/spec"

        # Get all files in the source directory
        files = Dir.glob("#{source_directory}/*")

        # Move each file to the destination directory
        files.each do |file|
          FileUtils.cp_r(file, destination_directory)
        end
      end

      def prepare_output_directory
        @path_utils.tmp_output_path
      end
    end
  end
end
