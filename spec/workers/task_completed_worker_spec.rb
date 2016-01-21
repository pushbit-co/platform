require 'spec_helper.rb'

describe "perform" do
  let(:worker) { Pushbit::TaskCompletedWorker.new }

  context "repo has bot" do
    let!(:behavior) { create(:behavior, kind: 'unbox') }
    let!(:repo) { create(:repo, github_id: 35_129_377, github_full_name: "baxterthehacker/public-repo") }
    let!(:trigger) { create(:trigger, kind: 'setup') }
    let!(:task) { create(:task, behavior: behavior, repo: repo, trigger: trigger) }

    context "bot has task_completed_kind trigger" do
      it "creates a trigger" do
        worker.perform(task.id)
        expect(Pushbit::Trigger.last.kind).to eql('task_completed_unbox')
        expect(Pushbit::TaskCompletedEventWorker.jobs.length).to eql(1)
      end
    end
  end
end
