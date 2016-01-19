require 'spec_helper.rb'

describe "create" do
  context "when unauthenticated" do
    it "should redirect to unauthenticated" do
      post '/actions', task_id: 1, kind: 'pull_request'
      expect(last_response.status).to eql(302)
    end
  end

  context "when authenticated" do
    let(:repo) { create(:repo, github_id: 123) }
    let(:trigger) { create(:trigger, kind: 'manual') }
    let(:task) { create(:task, repo: repo, trigger: trigger) }

    context "with required fields" do
      it "should respond with success" do
        post_with_basic_auth '/actions', task_id: task.id, repo_id: repo.id, kind: 'pull_request'
        expect(last_response.status).to eql(201)
        expect(last_json.action.id).to eql(Pushbit::Action.last.id)
        expect(last_json.action.kind).to eql('pull_request')
        expect(Pushbit::Action.last.repo).to eql(repo)
        expect(Pushbit::Action.last.task).to eql(task)
      end
    end

    context "without required fields" do
      it "should respond with failure" do
        post_with_basic_auth '/actions', task_id: task.id
        expect(last_response.status).to eql(422)
      end
    end
  end
end