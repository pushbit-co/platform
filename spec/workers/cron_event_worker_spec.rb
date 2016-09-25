require 'spec_helper.rb'

describe "perform" do
  let(:worker) { Pushbit::CronEventWorker.new }

  context "with cron behaviors" do
    let!(:behavior) { create(:behavior, kind: 'bundler-audit', tags:['Ruby'], triggers: ['cron']) }
    let(:image) { double(:image, id:"pushbit/tests") }
    let(:container) { double(:container, id:12345678, status:'start') }
    let(:containerJson) { {'State' => {'ExitCode' => 0}} }

    context "with inactive repo" do
      let!(:repo) { create(:repo, active: false, tags:['Ruby'], behaviors:[behavior]) }
      let!(:trigger) { create(:cron_trigger) }

      it "does not create a task" do
        worker.perform(trigger.id)
        expect(Pushbit::Task.count).to eql(0)
      end
    end

    context "with tasks not performed in last 24 hours" do
      let!(:repo) { create(:repo, tags:['Ruby'], behaviors:[behavior]) }
      let!(:repo2) { create(:repo, tags:['Ruby'], behaviors:[behavior]) }
      let!(:trigger) { create(:cron_trigger) }

      before do
        expect(container).to receive(:start).twice
        expect(container).to receive(:attach).twice
        expect(container).to receive(:remove).twice
        expect(container).to receive(:json).and_return(containerJson).twice
        expect(Docker::Image).to receive(:create).and_return(image).twice
        expect(Docker::Container).to receive(:create).and_return(container).twice
      end

      it "creates a new task per repo" do
        worker.perform(trigger.id)
        expect(Pushbit::Task.count).to eql(2)
        expect(Pushbit::Task.last.behavior).to eql(behavior)
      end
    end

    context "with tasks performed in last 24 hours" do
      let!(:repo) { create(:repo, tags:['Ruby'], behaviors:[behavior]) }
      let!(:trigger) { create(:cron_trigger) }
      let!(:task) { create(:task, trigger:trigger, repo:repo, behavior:behavior, completed_at: DateTime.now) }

      it "does not create a new task" do
        worker.perform(trigger.id)
        expect(Pushbit::Task.count).to eql(1)
        expect(Pushbit::Task.last.id).to eql(task.id)
      end
    end
  end
end
