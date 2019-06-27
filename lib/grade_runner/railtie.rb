require 'rails'

module GradeRunner
  class Railtie < ::Rails::Railtie

     rake_tasks do
      load "tasks/grade_runner.rake"
      load "tasks/grade.rake"
     end
  end
end
