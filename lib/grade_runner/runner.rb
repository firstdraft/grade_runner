require "net/http"
module GradeRunner
  class Runner

    def initialize(project_token, submission_url, grades_access_token)
      @project_token = project_token
      @submission_url = submission_url
      @grades_access_token = grades_access_token
      @rspec_output_json = nil
    end

    def process
      puts "* Running tests and submitting the results."
      dir = File.join(ENV['CIRCLE_ARTIFACTS'], "coverage")
      @rspec_output_json = JSON.parse(path)
      post_to_grades
    end

    private

    def post_to_grades
      uri = URI.parse(@submission_url)
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req.body = data.to_json
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
      results_url = JSON.parse(res.body)["url"]
      puts "- Done! Results URL: " + "#{results_url}"
    end

    def path
      File.read("#{ENV['CIRCLE_ARTIFACTS']}/output/rspec_output.json")
    end

    def data
      {
        project_token: @project_token,
        access_token: @grades_access_token,
        test_output: @rspec_output_json,
        commit_sha: ENV["CIRCLE_SHA1"],
        username: ENV["CIRCLE_PROJECT_USERNAME"],
        reponame: ENV["CIRCLE_PROJECT_REPONAME"]
      }
    end

  end
end
