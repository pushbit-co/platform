require 'spec_helper.rb'

describe "perform" do
  let(:worker) { Pushbit::TriggerWorker.new }
  let(:payload) { JSON.parse(File.read('spec/fixtures/github/issue_opened.json')) }
  let(:repo) { create(:repo) }
  let!(:behavior) { create(:behavior) }
  let(:trigger) { create(:github_issue_opened_trigger, payload: payload, repo: repo) }

  before do
    repo.behaviors << behavior
    repo.save!
  end

  it "calls execute! on active behaviors" do
    expect_any_instance_of(Pushbit::Behavior).to receive(:execute!).with(trigger)
    worker.perform(trigger.id)
  end
end
