require 'spec_helper.rb'

describe "create" do
  context "when unauthenticated" do
    it "should redirect to unauthenticated" do
      post '/discoveries', {task_id: 1, identifier: 'cve-123'}
      expect(last_response.status).to eql(302)
    end
  end
  
  context "when authenticated" do
    let(:repo) { Pushbit::Repo.create!(github_id: 123) }
    let(:trigger) { Pushbit::Trigger.create!(kind: 'manual') }
    let(:behavior) { Pushbit::Behavior.create!(kind: 'bundler-update', tone: 'negative', discovers: 'security issue') }
    let(:task) { Pushbit::Task.create!(behavior: behavior, trigger_id: trigger.id, repo_id: repo.id) }
    let(:action) { Pushbit::Action.create!(kind: 'issue', task_id: task.id, repo_id: repo.id, body: "test") }
    
    context "with required fields" do
      it "should respond with success" do
        post_with_basic_auth '/discoveries', {kind: 'security update', task_id: task.id, identifier: 'cve-123', title: "Some problem with security"}
        expect(last_response.status).to eql(201)
        expect(last_json.discovery.id).to eql(Pushbit::Discovery.last.id)
        expect(last_json.discovery.identifier).to eql('cve-123')
        expect(Pushbit::Discovery.last.task).to eql(task)
      end
      
      it "should update existing discoveries" do
        post_with_basic_auth '/discoveries', {kind: 'security update', task_id: task.id, identifier: 'cve-123', action_id: action.id, title: "Some problem"}
        expect(last_json.discovery.title).to eql("Some problem")

        post_with_basic_auth '/discoveries', {kind: 'security update', task_id: task.id, identifier: 'cve-123', title: "Some problem with security"}
        expect(last_response.status).to eql(201)
        expect(last_json.discovery.title).to eql("Some problem with security")
        expect(last_json.discovery.action_id).to eql(action.id)
      end
    end
    
    context "with detailed discoveries" do
      it "should respond with success" do
        post_with_basic_auth '/discoveries', {line: 12, column: 0, path: 'app.rb', kind: 'security update', task_id: task.id, identifier: 'cve-123', title: "Some problem with security"}
        expect(last_response.status).to eql(201)
        expect(last_json.discovery.id).to eql(Pushbit::Discovery.last.id)
        expect(last_json.discovery.identifier).to eql('cve-123')
        expect(Pushbit::Discovery.last.task).to eql(task)
        expect(Pushbit::Discovery.last.line).to eql(12)
        expect(Pushbit::Discovery.last.column).to eql(0)
        expect(Pushbit::Discovery.last.path).to eql('app.rb')
      end
    end
    
    context "without required fields" do
      it "should respond with failure" do
        post_with_basic_auth '/discoveries', {task_id: task.id}
        expect(last_response.status).to eql(422)
      end
    end
  end
end