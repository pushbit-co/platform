require 'spec_helper.rb'

describe "perform" do
  let(:payload) { File.read('spec/fixtures/github/pull_request.json') }
  let(:worker) { Pushbit::GithubEventWorker.new }

  context "push" do
    let(:payload) { File.read('spec/fixtures/github/push.json') }
    let!(:repo) { create(:repo, tags: ['Ruby']) }
    let!(:trigger) { create(:github_push_trigger, repo: repo) }

    it "does not request pr changed files" do
      worker.perform(trigger.id, payload)
    end
  end
  
  context "issue closed" do
    let(:payload) { File.read('spec/fixtures/github/issue_closed.json') }
    let!(:repo) { create(:repo, tags: ['Ruby']) }
    let!(:trigger) { create(:github_issue_closed_trigger, repo: repo) }
    let!(:action) { create(:action, github_status: 'opened', github_id: 73_464_126) }

    it "sets action to closed" do
      worker.perform(trigger.id, payload)
      expect(action.reload.github_status).to eql('closed')
    end
  end

  context "pull request closed" do
    let!(:repo) { create(:repo, tags: ['Ruby']) }
    let!(:trigger) { create(:github_pull_request_closed_trigger, repo: repo) }
    let!(:action) { create(:action, github_status: 'opened', github_id: 34_778_301) }

    it "sets action to closed" do
      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/git/refs/heads/#{action.task.branch}")
        .to_return(status: 200, body: "", headers: { "Content-Type" => "application/json" })

      worker.perform(trigger.id, payload)
      expect(action.reload.github_status).to eql('closed')
    end

    it "deletes branch if existing" do
      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/git/refs/heads/#{action.task.branch}")
        .to_return(status: 200, body: "{\"ref\": \"refs/heads/#{action.task.branch}\"}", headers: { "Content-Type" => "application/json" })

      stub_request(:delete, "https://api.github.com/repos/#{repo.github_full_name}/git/refs/heads/#{action.task.branch}")
        .to_return(status: 200, body: "", headers: { "Content-Type" => "application/json" })

      worker.perform(trigger.id, payload)

      expect(WebMock).to have_requested(:delete, "https://api.github.com/repos/#{repo.github_full_name}/git/refs/heads/#{action.task.branch}")
    end
  end

  context "pull request merged" do
    let(:payload) { File.read('spec/fixtures/github/pull_request_merged.json') }
    let!(:repo) { create(:repo, tags: ['Ruby']) }
    let!(:trigger) { create(:github_pull_request_closed_trigger, repo: repo) }
    let!(:action) { create(:action, github_status: 'opened', github_id: 34_778_301) }

    it "sets action to closed" do
      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/git/refs/heads/#{action.task.branch}")
        .to_return(status: 404, body: "", headers: { "Content-Type" => "application/json" })

      worker.perform(trigger.id, payload)
      expect(action.reload.github_status).to eql('merged')
    end

    it "deletes branch if existing" do
      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/git/refs/heads/#{action.task.branch}")
        .to_return(status: 200, body: "{\"ref\": \"refs/heads/#{action.task.branch}\"}", headers: { "Content-Type" => "application/json" })

      stub_request(:delete, "https://api.github.com/repos/#{repo.github_full_name}/git/refs/heads/#{action.task.branch}")
        .to_return(status: 200, body: "", headers: { "Content-Type" => "application/json" })

      worker.perform(trigger.id, payload)

      expect(WebMock).to have_requested(:delete, "https://api.github.com/repos/#{repo.github_full_name}/git/refs/heads/#{action.task.branch}")
    end
  end

  context "pull request opened" do
    context "repo has no bots" do
      let!(:repo) { create(:repo, tags: ['Ruby']) }
      let!(:trigger) { create(:github_pull_request_opened_trigger, repo: repo) }

      it "creates no tasks" do
        stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/pulls/1/files?per_page=100")
          .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/pull_request_changed_files.json'), headers: { "Content-Type" => "application/json" })

        worker.perform(trigger.id, payload)
        expect(Pushbit::Task.count).to eql(0)
      end
    end

    context "repo has inactive bot" do
      let!(:behavior) { create(:behavior, active: false, kind: 'bundler-update', tags: ['Ruby'], files: ['Gemfile', 'Gemfile.lock'], triggers: ['pull_request']) }
      let!(:repo) { create(:repo, tags: ['Ruby'], behaviors: [behavior]) }
      let!(:trigger) { create(:github_pull_request_opened_trigger, repo: repo) }

      it "creates no tasks" do
        stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/pulls/1/files?per_page=100")
          .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/pull_request_changed_files_ruby.json'), headers: { "Content-Type" => "application/json" })

        worker.perform(trigger.id, payload)
        expect(Pushbit::Task.count).to eql(0)
      end
    end

    context "repo has bot" do
      let!(:behavior) { create(:behavior, kind: 'bundler-update', tags: ['Ruby'], files: ['Gemfile', 'Gemfile.lock'], triggers: ['pull_request_opened']) }
      let!(:repo) { create(:repo, tags: ['Ruby'], behaviors: [behavior]) }
      let!(:trigger) { create(:github_pull_request_opened_trigger, repo: repo) }

      context "changed files not relevant" do
        it "creates no tasks" do
          stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/pulls/1/files?per_page=100")
            .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/pull_request_changed_files.json'), headers: { "Content-Type" => "application/json" })

          worker.perform(trigger.id, payload)
          expect(Pushbit::Task.count).to eql(0)
        end
      end

      context "changed files are relevant" do
        let(:image) { double(:image, id: "pushbit/tests") }
        let(:container) { double(:container, id: 12_345_678, status: 'start') }

        before do
          Docker::Image.stub(:create).and_return(image)
          Docker::Container.stub(:create).and_return(container)
          container.stub(:start)
        end

        it "creates a task" do
          stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/pulls/1/files?per_page=100")
            .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/pull_request_changed_files_ruby.json'), headers: { "Content-Type" => "application/json" })

          worker.perform(trigger.id, payload)
          expect(Pushbit::Task.count).to eql(1)
          expect(Pushbit::Task.last.commit).to eql('0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c')
          expect(Pushbit::Task.last.behavior).to eql(behavior)
          expect(Pushbit::Task.last.repo).to eql(repo)
        end

        it "creates a container" do
          stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/pulls/1/files?per_page=100")
            .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/pull_request_changed_files_ruby.json'), headers: { "Content-Type" => "application/json" })

          Pushbit::Task.any_instance.stub(:id).and_return(1)

          expect(Pushbit::DockerContainerWorker).to receive(:perform_async).with(
            1,
            ["app.rb", "Gemfile"],
            "0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c"
          )
          worker.perform(trigger.id, payload)
        end
      end
    end
  end
end