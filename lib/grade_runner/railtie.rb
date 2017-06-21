require 'rails'

module GradeRunner
  class Railtie < ::Rails::Railtie

     rake_tasks do
      load "tasks/grade_runner.rake"
     end
  end
end
