require 'spec_helper.rb'

describe "perform" do
  let(:worker) { Pushbit::BehaviorSyncronizationWorker.new }

  context "with valid config.yml" do
    it "adds behaviors to database" do
      stub_request(:get, "https://api.github.com/orgs/pushbit-behaviors/repos?per_page=100")
        .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/pushbit_behaviors_repos.json'), headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "https://raw.githubusercontent.com/pushbit-behaviors/bundler-audit/master/config.yml")
        .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/bundler_audit_config.yml'), headers: {})

      stub_request(:get, "https://raw.githubusercontent.com/pushbit-behaviors/bundler-update/master/config.yml")
        .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/bundler_update_config.yml'), headers: {})

      worker.perform
      expect(Pushbit::Behavior.count).to eql(2)
      expect(Pushbit::Behavior.active.count).to eql(2)
      expect(Pushbit::Behavior.find_by(kind: 'bundler-audit').name).to eql('Bundler Audit')
      expect(Pushbit::Behavior.find_by(kind: 'bundler-audit').repository_url).to eql('http://example.com')
      expect(Pushbit::Behavior.find_by(kind: 'bundler-audit').author_name).to eql('Alex')
      expect(Pushbit::Behavior.find_by(kind: 'bundler-update').name).to eql('Bundler Update')
      expect(Pushbit::Behavior.find_by(kind: 'bundler-update').settings).to eql({
        "filter"=>{"label"=>"Filter to a specific team", "type"=>"string"},
        "color"=>{"label"=>"Choose a color", "type"=>"string", "options"=>["red", "green", "blue"]}
      })
    end
  end

  context "with missing config.yml" do
    it "skips importing behavior and continues" do
      stub_request(:get, "https://api.github.com/orgs/pushbit-behaviors/repos?per_page=100")
        .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/pushbit_behaviors_repos.json'), headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "https://raw.githubusercontent.com/pushbit-behaviors/bundler-audit/master/config.yml")
        .to_return(status: 404, body: File.read('spec/fixtures/github/webmock/bundler_audit_config.yml'), headers: {})

      stub_request(:get, "https://raw.githubusercontent.com/pushbit-behaviors/bundler-update/master/config.yml")
        .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/bundler_update_config.yml'), headers: {})

      worker.perform
      expect(Pushbit::Behavior.count).to eql(1)
      expect(Pushbit::Behavior.active.count).to eql(1)
      expect(Pushbit::Behavior.find_by(kind: 'bundler-update').name).to eql('Bundler Update')
    end
  end

  context "with corrupt config.yml" do
    it "skips importing behavior and continues" do
      stub_request(:get, "https://api.github.com/orgs/pushbit-behaviors/repos?per_page=100")
        .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/pushbit_behaviors_repos.json'), headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "https://raw.githubusercontent.com/pushbit-behaviors/bundler-audit/master/config.yml")
        .to_return(status: 200, body: "///CORRUPT///", headers: {})

      stub_request(:get, "https://raw.githubusercontent.com/pushbit-behaviors/bundler-update/master/config.yml")
        .to_return(status: 200, body: File.read('spec/fixtures/github/webmock/bundler_update_config.yml'), headers: {})

      worker.perform
      expect(Pushbit::Behavior.count).to eql(1)
      expect(Pushbit::Behavior.active.count).to eql(1)
      expect(Pushbit::Behavior.find_by(kind: 'bundler-update').name).to eql('Bundler Update')
    end
  end

  context "with behavior missing" do
    before do
      Pushbit::Behavior.find_or_create_with(
        kind: 'filecop',
        name: 'Filecop',
        description: "Detects potentially hazardeous commited files such as keys, tokens and certs",
        discovers: "sensitive file",
        tone: 'negative',
        active: true
      )
    end
  end
end
