require "grade_runner/runner"
require "grade_runner/railtie" if defined?(Rails)

module GradeRunner
  class Error < StandardError; end

  class << self
    attr_writer :default_points, :override_local_specs

    def default_points
      @default_points || 1
    end

    def override_local_specs
      if @override_local_specs.nil?
        "OOPS"
      else
        "FALSE"#@override_local_specs
      end
    end

    def config
      yield self
    end
  end

  def self.init
    puts "====="
    puts @default_points
    puts @override_local_specs
  end
end
