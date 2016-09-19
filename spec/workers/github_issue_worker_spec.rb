require 'spec_helper.rb'

describe "perform" do
  #let(:worker) { Pushbit::GithubIssueWorker.new }
  let!(:repo) { create(:repo) }
  let(:trigger) {create(:trigger, repo:repo) }
  let(:task) { create(:task, behavior:behavior, repo:repo, trigger:trigger) }
  let!(:behavior) { create(:behavior, kind: 'bundler-update') }

  before { skip("Disabled whilst converting") }

  it "creates an issue on github" do
    stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/labels?per_page=100").
      to_return(:status => 200, :body => "[{\"name\": \"bug\"}]", :headers => {"Content-Type" => "application/json"})

      stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/issues").
      to_return(:status => 200, :body => "{\"id\": 123, \"html_url\": \"http://www.example.com\"}", :headers => {"Content-Type" => "application/json"})

    worker.perform(task.id)
    expect(Pushbit::Action.count).to eql(1)
    expect(Pushbit::Action.last.kind).to eql('issue')
    expect(Pushbit::Action.last.github_id).to eql(123)
    expect(Pushbit::Action.last.github_url).to eql('http://www.example.com')
  end

  context "when a single discovery" do
    let!(:disc) { task.discoveries.create(kind: 'bundle update', identifier: 123, title: "bundle update", message: "your bundle was updated") }

    it "uses discovery title for issue title" do
      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/labels?per_page=100").
        to_return(:status => 200, :body => "[{\"name\": \"bug\"}]", :headers => {"Content-Type" => "application/json"})

        stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/issues").
        to_return(:status => 200, :body => "{\"id\": 123, \"html_url\": \"http://www.example.com\"}", :headers => {"Content-Type" => "application/json"})

      worker.perform(task.id)

      expect(WebMock).to have_requested(:post, "https://api.github.com/repos/#{repo.github_full_name}/issues").
        with(:body => '{"labels":["bug","pushbit"],"title":"Bundle update","body":"your bundle was updated"}')
    end
  end
end
