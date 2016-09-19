require 'spec_helper.rb'

describe "perform" do
  #let!(:worker) { Pushbit::GithubPullRequestWorker.new }
  let!(:repo) { create(:repo) }
  let(:behavior) { create(:behavior, kind: 'rubocop', tone: 'negative', discovers: 'style issue') }

  before { skip("Disabled whilst converting") }

  context "with manual trigger" do
    let(:trigger) { create(:trigger, repo: repo) }
    let(:task) { create(:task, repo: repo, trigger: trigger, behavior: behavior) }
    let!(:discovery) { create(:discovery, title: "Whitespace", path: "app.rb", identifier: 2, kind: 'style violation', task: task, line: 22, message: "Missing semicolon after return") }

    it "creates a pull request on github" do
      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/labels?per_page=100")
        .to_return(status: 200, body: "[{\"name\": \"bug\"}]", headers: { "Content-Type" => "application/json" })

      stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/pulls")
        .to_return(status: 200, body: "{\"id\": 123, \"html_url\": \"http://www.example.com\"}", headers: { "Content-Type" => "application/json" })

      worker.perform(task.id)
      expect(Pushbit::Action.count).to eql(1)
      expect(Pushbit::Action.last.kind).to eql('pull_request')
      expect(Pushbit::Action.last.github_id).to eql(123)
      expect(Pushbit::Action.last.github_url).to eql('http://www.example.com')
      expect(Pushbit::Action.last.title).to eql("Whitespace")
    end

    it "handles pull request already existing" do
      error_response = {
        "message" => "Validation Failed",
        "errors" => [
          {
            "resource" => "PullRequest",
            "field" => "custom",
            "code" => "A pull request already exists"
          }
        ]
      }

      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/labels?per_page=100")
        .to_return(status: 200, body: "[{\"name\": \"bug\"}]", headers: { "Content-Type" => "application/json" })

      stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/pulls")
        .to_return(status: 422, body: error_response.to_json, headers: { "Content-Type" => "application/json" })

      worker.perform(task.id)
      expect(Pushbit::Action.count).to eql(0)
    end
  end

  context "when pull request opened" do
    let(:trigger) { create(:github_pull_request_opened_trigger, repo: repo) }
    let(:task) { create(:task, repo: repo, trigger: trigger, behavior: behavior) }
    let!(:discovery) { create(:discovery, title: "Whitespace", path: "app.rb", identifier: 2, kind: 'style violation', task: task, line: 22, message: "Missing semicolon after return") }

    context "with open pull request from trigger" do
      it "creates a pull request on github" do
        stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/labels?per_page=100")
          .to_return(status: 200, body: "[{\"name\": \"bug\"}]", headers: { "Content-Type" => "application/json" })

        stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/pulls/#{trigger.payload['number']}")
          .to_return(status: 200, body: "{\"id\": 123, \"number\": #{trigger.payload['number']}, \"state\": \"open\"}", headers: { "Content-Type" => "application/json" })

        stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/pulls")
          .to_return(status: 200, body: "{\"id\": 123, \"html_url\": \"http://www.example.com\"}", headers: { "Content-Type" => "application/json" })

        worker.perform(task.id)
        expect(Pushbit::Action.count).to eql(1)
        expect(Pushbit::Action.last.kind).to eql('pull_request')
        expect(Pushbit::Action.last.github_id).to eql(123)
        expect(Pushbit::Action.last.github_url).to eql('http://www.example.com')
        expect(Pushbit::Action.last.title).to eql("Whitespace")
      end
    end

    context "with closed pull request from trigger" do
      it "does not create a pull request" do
        stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/labels?per_page=100")
          .to_return(status: 200, body: "[{\"name\": \"bug\"}]", headers: { "Content-Type" => "application/json" })

        stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/pulls/#{trigger.payload['number']}")
          .to_return(status: 200, body: "{\"id\": 123, \"number\": #{trigger.payload['number']}, \"state\": \"closed\"}", headers: { "Content-Type" => "application/json" })

        worker.perform(task.id)
        expect(Pushbit::Action.count).to eql(0)
      end
    end
  end
end
