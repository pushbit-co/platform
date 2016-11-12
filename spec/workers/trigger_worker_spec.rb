require 'spec_helper.rb'
require 'parallel'

describe "perform" do
  let(:worker) { Pushbit::TriggerWorker.new }
  let(:repo) { create(:repo, github_id: 123) }
  let!(:trigger) { create(:trigger, kind: :pull_request_opened, repo: repo) }

  context "with no active behaviors" do
    it "does not clone the code" do
      worker.work(trigger.id, {})
      expect(worker).not_to receive(:clone!)
    end
  end

  context "with active behaviors" do
    let!(:behavior) { create(:behavior, triggers: [:pull_request_opened]) }
    let(:volume) { double }

    before do
      repo.behaviors = [behavior]
      repo.save!
    end

    it "clones the code" do
      allow_any_instance_of(Pushbit::Behavior).to receive(:execute!)
      expect(volume).to receive(:remove)
      expect(Pushbit::Dockertron).to receive(:clone!).and_return(volume)
      worker.work(trigger.id, {})
    end
  end
end
