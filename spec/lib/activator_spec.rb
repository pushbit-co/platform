require 'spec_helper'

describe Pushbit::Activator do
  let(:user) { create(:user) }
  let(:repo) { create(:repo, private: true) }
  let(:key) { double }

  describe "activate" do
    it "adds a webhook to repo" do
      stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/hooks")
        .to_return(status: 201, body: "{\"id\": \"123\"}", headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
        .to_return(status: 204, headers: { 'Content-Type' => 'application/json' })

      stub_request(:put, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
        .to_return(status: 201, body: "{\"id\": 123}", headers: { 'Content-Type' => 'application/json' })

      stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/keys")
        .to_return(:status => 201, :body => "{\"id\": 123}", headers: { 'Content-Type' => 'application/json' })

      Pushbit::Activator.activate(repo, user)
      expect(repo.webhook_id).to eql('123')
      expect(repo.active).to eql(true)
    end

    it "adds a collaborator to repo" do
      stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/hooks")
        .to_return(status: 201, body: "{\"id\": 123}", headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
        .to_return(status: 404, headers: { 'Content-Type' => 'application/json' })

      stub_request(:put, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
        .to_return(status: 201, body: "{\"id\": 123}", headers: { 'Content-Type' => 'application/json' })

      stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/keys")
        .to_return(:status => 201, :body => "{\"id\": 123}", headers: { 'Content-Type' => 'application/json' })

      expect(user.client).to receive(:add_collaborator)
      Pushbit::Activator.activate(repo, user)
      expect(repo.active).to eql(true)
    end

    # it "adds a deploy key to repo" do
    #   stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/hooks")
    #     .to_return(status: 201, body: "{\"id\": 123}", headers: { 'Content-Type' => 'application/json' })
    #
    #   stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
    #     .to_return(status: 404, headers: { 'Content-Type' => 'application/json' })
    #
    #   stub_request(:put, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
    #     .to_return(status: 201, body: "{\"id\": 123}", headers: { 'Content-Type' => 'application/json' })
    #
    #   stub_request(:post, "https://api.github.com/repos/#{repo.github_full_name}/keys")
    #     .to_return(:status => 201, :body => "{\"id\": 123}", headers: { 'Content-Type' => 'application/json' })
    #
    #   expect(key).to receive(:id).and_return(123)
    #   expect(user.client).to receive(:add_deploy_key).and_return(key)
    #   Pushbit::Activator.activate(repo, user)
    #   expect(repo.active).to eql(true)
    #   expect(repo.deploy_key_id).to eql(123)
    # end
  end

  describe "deactivate" do
    it "removes webhook if existing" do
      repo.webhook_id = 456

      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
        .to_return(status: 204, headers: { 'Content-Type' => 'application/json' })

      stub_request(:delete, "https://api.github.com/repos/#{repo.github_full_name}/hooks/#{repo.webhook_id}")
        .to_return(status: 204, body: "", headers: { 'Content-Type' => 'application/json' })

      stub_request(:delete, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
        .to_return(status: 204, headers: {})

      Pushbit::Activator.deactivate(repo, user)
      expect(repo.webhook_id).to eql(nil)
      expect(repo.active).to eql(false)
    end

    it "does not remove webhook if missing" do
      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
        .to_return(status: 200, body: "{\"id\": 123}", headers: { 'Content-Type' => 'application/json' })

      stub_request(:delete, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
        .to_return(status: 204, headers: {})

      expect(user.client).not_to receive(:remove_hook)
      Pushbit::Activator.deactivate(repo, user)
      expect(repo.active).to eql(false)
    end

    it "removes collaborator" do
      stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
        .to_return(status: 204, headers: { 'Content-Type' => 'application/json' })

      stub_request(:delete, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
        .to_return(status: 204, headers: {})

      expect(user.client).to receive(:remove_collaborator)
      Pushbit::Activator.deactivate(repo, user)
      expect(repo.active).to eql(false)
    end

    # it "removes deploy key" do
    #   repo.deploy_key_id = 456
    #
    #   stub_request(:get, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
    #     .to_return(status: 204, headers: { 'Content-Type' => 'application/json' })
    #
    #   stub_request(:delete, "https://api.github.com/repos/#{repo.github_full_name}/collaborators/dev-pushbit-bot")
    #     .to_return(status: 204, headers: {})
    #
    #   expect(user.client).to receive(:remove_deploy_key)
    #   Pushbit::Activator.deactivate(repo, user)
    #   expect(repo.active).to eql(false)
    # end
  end
end
