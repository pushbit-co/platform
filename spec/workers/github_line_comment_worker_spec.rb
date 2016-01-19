require 'spec_helper.rb'

describe "perform" do
  let(:worker) { Pushbit::GithubLineCommentWorker.new }
  let!(:repo) { create(:repo) }
  let(:trigger) { create(:trigger, repo:repo) }
  let(:behavior) { create(:behavior, kind:'bundle-update') }
  let(:task) { create(:task, behavior:behavior, repo:repo, trigger:trigger) }

  context "with multiple discoveries on the same line" do
    let!(:discovery2) { Pushbit::Discovery.create(path: "app.rb", identifier: 2, kind: 'style violation', task: task, line: 22, message: "Missing semicolon") }
    let!(:discovery3) { Pushbit::Discovery.create(path: "app.rb", identifier: 3, kind: 'style violation', task: task, line: 22, message: "Trailing whitespace") }

    it "creates a single comment" do
      body = JSON.parse File.read('spec/fixtures/github/webmock/pull_request_changed_files_ruby.json')
      body.first['patch'] = File.read('spec/fixtures/patch.diff')
    
      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/pulls/#{trigger.payload["number"]}/files?per_page=100").
      to_return(:status => 200, :body => body.to_json, :headers => {"Content-Type" => "application/json"})
    
      stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/pulls/#{trigger.payload["number"]}/comments").
        to_return(:status => 200, :body => "{\"id\": 123}", :headers => {"Content-Type" => "application/json"})
    
      worker.perform(task.id)
      expect(Pushbit::Action.count).to eql(1)
      expect(Pushbit::Action.last.kind).to eql('line_comment')
      expect(Pushbit::Action.last.github_id).to eql(123)
    end
  end
  
  context "with multiple discoveries on different lines" do
    let!(:discovery2) { Pushbit::Discovery.create(path: "app.rb", identifier: 2, kind: 'style violation', task: task, line: 22, message: "Missing semicolon") }
    let!(:discovery3) { Pushbit::Discovery.create(path: "app.rb", identifier: 3, kind: 'style violation', task: task, line: 54, message: "Trailing whitespace") }

    it "creates multiple line comments" do
      body = JSON.parse File.read('spec/fixtures/github/webmock/pull_request_changed_files_ruby.json')
      body.first['patch'] = File.read('spec/fixtures/patch.diff')
    
      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/pulls/#{trigger.payload["number"]}/files?per_page=100").
      to_return(:status => 200, :body => body.to_json, :headers => {"Content-Type" => "application/json"})
    
      stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/pulls/#{trigger.payload["number"]}/comments").
        to_return(:status => 200, :body => "{\"id\": 123}", :headers => {"Content-Type" => "application/json"})
    
      worker.perform(task.id)
      expect(Pushbit::Action.count).to eql(2)
      expect(Pushbit::Action.last.kind).to eql('line_comment')
      expect(Pushbit::Action.last.github_id).to eql(123)
    end
  end
end
