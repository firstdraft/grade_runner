require "net/http"
module GradeRunner
  class Runner

    def initialize(project_token, submission_url, grades_access_token, rspec_output_json, username, reponame, sha)
      @project_token = project_token
      @submission_url = submission_url
      @grades_access_token = grades_access_token
      @rspec_output_json = rspec_output_json
      @username = username
      @reponame = reponame
      @sha = sha
    end

    def process
      puts "* Submitting the results."
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

    def data
      {
        project_token: @project_token,
        access_token: @grades_access_token,
        test_output: @rspec_output_json,
        commit_sha: @sha,
        username: @username,
        reponame: @reponame
      }
    end

  end
end
