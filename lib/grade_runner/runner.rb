require "net/http"
require "oj"

module GradeRunner
  class Runner

    def initialize(submission_root_url, grades_access_token, rspec_output_json, username, reponame, sha, source)
      @submission_url = submission_root_url + submission_path
      @grades_access_token = grades_access_token
      @rspec_output_json = rspec_output_json
      @username = username
      @reponame = reponame
      @sha = sha
      @source = source
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

      results_url = Oj.load(res.body)["url"]
      puts "- Done! Results URL: " + "#{results_url}"
    end

    def submission_path
      "/builds"
    end

    def data
      {
        access_token: @grades_access_token,
        test_output: @rspec_output_json,
        commit_sha: @sha,
        username: @username,
        reponame: @reponame,
        source: @source
      }
    end

  end
end
