require 'spec_helper'

describe Pushbit::ActionCreator do
  let(:repo) { create(:repo, github_id: 123) }
  let(:trigger) { create(:trigger, kind: 'pull_request') }
  let(:task) { create(:task, repo: repo, trigger: trigger) }

  describe "pull_request" do
    let(:title) { 'PR title' }
    let(:body) { 'PR body' }

    it "creates a pull request and action" do
      stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/pulls")
        .to_return(status: 200, body: "{\"id\": 123, \"html_url\": \"http://www.example.com\"}", headers: { "Content-Type" => "application/json" })

      params = {task_id: task.id, title: title, body: body, kind: 'pull_request'}
      action = Pushbit::ActionCreator.pull_request(repo, task, params)
      expect(action.kind).to eql('pull_request')
      expect(action.github_id).to eql(123)
      expect(action.github_url).to eql('http://www.example.com')
      expect(action.title).to eql(title)
      expect(Pushbit::Action.count).to eql(1)
    end
  end

  describe "issue" do
    let(:title) { 'Issue title' }
    let(:body) { 'Issue body' }

    it "creates an issue and action" do
      stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/issues")
        .to_return(:status => 200, :body => "{\"id\": 123, \"html_url\": \"http://www.example.com\"}", :headers => {"Content-Type" => "application/json"})

      params = {task_id: task.id, title: title, body: body, kind: 'issue'}
      action = Pushbit::ActionCreator.issue(repo, task, params)
      expect(action.kind).to eql('issue')
      expect(action.github_id).to eql(123)
      expect(action.github_url).to eql('http://www.example.com')
      expect(action.title).to eql(title)
      expect(Pushbit::Action.count).to eql(1)
    end
  end
end
