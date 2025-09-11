module GradeRunner
  module Utils
    class PathUtils
      class << self
        # Determine the project root directory
        # @return [Pathname] The project root path
        def project_root
          if defined?(Rails)
            Rails.root
          elsif defined?(Bundler)
            Bundler.root
          else
            Pathname.new(Dir.pwd)
          end
        end

        # Create a path relative to project root
        # @param path [String] Relative path
        # @return [Pathname] Absolute path from project root
        def path_in_project(path)
          project_root.join(path)
        end

        # Find or create a directory in the project
        # @param directory_name [String] Directory name to find or create
        # @return [String] Path to the directory
        def find_or_create_directory(directory_name)
          directory = path_in_project(directory_name)
          FileUtils.mkdir_p(directory) unless Dir.exist?(directory)
          directory.to_s
        end

        # Get the temporary output directory path for test results
        # @return [String] Path to the output directory
        def tmp_output_path
          output_dir = find_or_create_directory("tmp/output")
          File.join(output_dir, "#{Time.now.to_i}.json")
        end

        # Get the temporary directory path
        # @return [String] Path to the temporary directory
        def tmp_path
          find_or_create_directory("tmp")
        end
      end
    end
  end
end
