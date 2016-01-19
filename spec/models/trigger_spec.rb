require 'spec_helper'

describe Pushbit::Trigger do
  let(:repo) { Pushbit::Repo.create!(github_id: 123_456, github_full_name: "baxterthehacker/public-repo") }

  describe "save" do
    it "is valid with kind" do
      trigger = Pushbit::Trigger.new(kind: "cron", repo: repo)
      expect(trigger.valid?).to eql(true)
    end

    it "is invalid without kind" do
      trigger = Pushbit::Trigger.new(repo: repo)
      expect(trigger.valid?).to eql(false)
      expect { trigger.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end