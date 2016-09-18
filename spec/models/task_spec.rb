require 'spec_helper'

describe Pushbit::Task do
  let(:repo) { create(:repo, github_id: 123_456, github_full_name: "baxterthehacker/public-repo") }
  let(:trigger) { create(:trigger, kind: 'manual') }
  let(:behavior) { create(:behavior, kind: 'bundler-update', tone: 'negative') }
  let(:task) { create(:task, behavior: behavior, trigger: trigger, repo: repo) }
  let!(:user) { create(:user, github_id: 123_456, login: 'tommoor') }

  describe "save" do
    it "is invalid with invalid status" do
      task = Pushbit::Task.new(trigger_id: trigger.id, repo_id: repo.id, status: "blah")
      expect { task.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "is invalid with invalid container status" do
      task = Pushbit::Task.new(trigger_id: trigger.id, repo_id: repo.id, container_status: "exit")
      expect { task.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "is invalid without a repo" do
      task = Pushbit::Task.new(trigger_id: trigger.id)
      expect { task.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "is invalid without a trigger" do
      task = Pushbit::Task.new(repo_id: repo.id)
      expect { task.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "triggered_by_login" do
    it "returns organization by default" do
      expect(task.triggered_by_login).to eql('pushbit-co')
    end

    it "returns user login if triggerer" do
      trigger.update_attribute(:triggered_by, 123_456)
      expect(task.reload.triggered_by_login).to eql('tommoor')
    end
  end

  describe "labels" do
    it "returns default value" do
      stub_request(:get, "https://api.github.com/repos/baxterthehacker/public-repo/labels?per_page=100")
        .to_return(status: 200, body: "[{\"name\": \"enhancement\"}]", headers: { "Content-Type" => "application/json" })

      expect(task.labels).to eql(['pushbit'])
    end
  end
end
