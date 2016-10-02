require 'spec_helper'

describe Pushbit::Dockertron do
  let(:repo) { create(:repo, github_id: 123) }
  let(:trigger) { create(:trigger, kind: 'pull_request', repo: repo) }
  let(:task) { create(:task, repo: repo, trigger: trigger) }
  let(:image) { double(:image, id: "pushbit/tests") }
  let(:volume) { double(:volume, id: "pushbit/tests") }
  let(:container) { double(:container, id:12345678, status:'start') }
  let(:containerJson) { {'State' => {'ExitCode' => 0}} }

  describe "clone!" do
    before do
      expect(container).to receive(:start)
      expect(container).to receive(:attach)
      expect(container).to receive(:remove)
      expect(container).to receive(:json).and_return(containerJson)
      expect(Docker::Image).to receive(:create).and_return(image)
      expect(Docker::Container).to receive(:create).and_return(container)
    end

    it "creates and returns correctly named volume" do
      expect(Docker::Volume).to receive(:create).and_return(volume)
      result = Pushbit::Dockertron.clone!(trigger)
      expect(result).to equal(volume)
    end
  end

  describe "run_task!" do
    before do
      expect(container).to receive(:start)
      expect(container).to receive(:attach)
      expect(container).to receive(:remove)
      expect(container).to receive(:json).and_return(containerJson)
      expect(Docker::Image).to receive(:create).and_return(image)
    end

    it "creates a container with correct parameters" do
      expect(Docker::Container).to receive(:create).with(
        hash_including(
          "Image" => "pushbit/tests",
          "Env" => [
            "PUSHBIT_SSH_KEY=#{repo.unencrypted_ssh_key}",
            "PUSHBIT_USERNAME=#{repo.github_owner}",
            "PUSHBIT_REPONAME=#{repo.name}",
            "PUSHBIT_APP_URL=#{ENV.fetch('APP_URL')}",
            "PUSHBIT_REPOSITORY_URL=https://github.com/#{repo.github_full_name}",
            "PUSHBIT_CHANGED_FILES=",
            "PUSHBIT_TASK_ID=#{task.id}",
            "PUSHBIT_API_TOKEN=#{task.access_token}",
            "PUSHBIT_PR_NUMBER=#{task.trigger.payload['number']}",
            "PUSHBIT_BASE_COMMIT=#{task.trigger.payload['pull_request']['head']['sha']}",
            "PUSHBIT_BASE_BRANCH=master"
          ]
        )
      ).and_return(container)
      Pushbit::Dockertron.run_task!(task, [])
    end
  end
end
