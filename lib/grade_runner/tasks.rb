# frozen_string_literal: true

require "rake" unless defined?(Rake)

# Load any .rake files nested under lib/grade_runner/tasks/
Dir[File.expand_path("tasks/**/*.rake", __dir__)].sort.each do |file|
  load file
end
