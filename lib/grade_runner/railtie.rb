require 'rails'

module GradeRunner
  class Railtie < ::Rails::Railtie
    rake_tasks { load "grade_runner/tasks.rb" }
  end
end
