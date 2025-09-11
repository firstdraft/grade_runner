# lib/grade_runner/test_helpers.rb
require "stringio"

module GradeRunner
  ##
  # TestHelpers provides small utilities for writing exercise specs
  # that need to capture program output. These helpers keep specs
  # short, readable, and consistent across projects.
  #
  # Example usage (RSpec):
  #
  #   # spec/spec_helper.rb
  #
  #   require "bundler/setup"   # !important so the Gemfile dependencies are on $LOAD_PATH
  #   require "grade_runner/test_helpers"
  #
  #   RSpec.configure do |config|
  #     config.include GradeRunner::TestHelpers
  #   end
  #
  #   # spec/example_spec.rb
  #
  #   it "captures script output" do
  #     lines = run_ruby_lines("./hello.rb")
  #     expect(lines).to eq(["hello, world"])
  #   end
  #
  module TestHelpers
    Status = Struct.new(:exitstatus) do
      def success? = exitstatus.to_i == 0
    end

    # Run a Ruby script (in-process) and capture stdout, stderr, and status.
    # Works with RSpec stubs because no subprocess is spawned.
    #
    # @param path [String] e.g. "./calculator.rb"
    # @param stdin [String] content for gets/$stdin (include trailing "\n"s)
    # @param argv [Array<String>] values to replace ARGV with
    # @return [Array(String, String, Status)] [stdout, stderr, status]
    def run_script(path, stdin: "", argv: [])
      orig_stdin, orig_stdout, orig_stderr = $stdin, $stdout, $stderr
      orig_argv = ARGV.dup

      in_buf  = StringIO.new(String(stdin))
      out_buf = StringIO.new
      err_buf = StringIO.new

      $stdin  = in_buf
      $stdout = out_buf
      $stderr = err_buf
      ARGV.replace(Array(argv))

      status = Status.new(0)

      begin
        load path
      rescue SystemExit => e
        status.exitstatus = e.status || 1
      rescue Exception => e
        err_buf.puts("#{e.class}: #{e.message}")
        e.backtrace&.each { |ln| err_buf.puts(ln) }
        status.exitstatus = 1
      ensure
        $stdin  = orig_stdin
        $stdout = orig_stdout
        $stderr = orig_stderr
        ARGV.replace(orig_argv)
      end

      [out_buf.string, err_buf.string, status]
    end
    alias run_ruby run_script

    # Run a script and return cleaned lines (quotes stripped, trimmed, no blanks).
    #
    # @return [Array<String>]
    def run_script_and_capture_lines(path, stdin: "", argv: [])
      stdout, _stderr, _status = run_ruby(path, stdin:, argv:)
      clean_output_lines(stdout)
    end
    alias run_ruby_and_capture_lines run_script_and_capture_lines

    # Run a script and return raw stdout (string).
    #
    # @return [String]
    def capture_raw_stdout_from(path, stdin: "", argv: [])
      stdout, _stderr, _status = run_ruby(path, stdin:, argv:)
      stdout
    end

    # Normalize printed output into human-friendly lines:
    # - remove pp quotes
    # - split lines
    # - strip whitespace
    # - drop empties
    #
    # @param output [String]
    # @return [Array<String>]
    def normalize_output(output)
      output.gsub('"', "").lines.map(&:strip).reject(&:empty?)
    end
    alias clean_output_lines normalize_output

    # Remove comment-only lines from source text.
    #
    # @param source [String]
    # @return [String]
    def strip_comments(source)
      source.lines.reject { |line| line.strip.start_with?("#") }.join
    end
    alias strip_comment_lines strip_comments
  end
end
