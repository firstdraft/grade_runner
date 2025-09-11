require "active_support/core_ext/object/blank"
require "grade_runner/services/grade_service"

desc "Alias for \"grade:all\"."
task grade: "grade:all" do
end

namespace :grade do
  desc "Run all tests and submit a build report."
  task :all do
    ARGV.each { |a| task a.to_sym do ; end }
    input_token = ARGV[1]

    grade_service = GradeRunner::Services::GradeService.new
    result = grade_service.process_grade_all(input_token)

    puts result if result.present?
  end

  desc "Reset access token saved in YAML file."
  task :reset_token do
    grade_service = GradeRunner::Services::GradeService.new
    result = grade_service.process_reset_token

    puts result if result.present?
  end
end
