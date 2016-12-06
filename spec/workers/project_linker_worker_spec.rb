require 'spec_helper.rb'

describe "perform" do
  let(:worker) { Pushbit::ProjectLinkerWorker.new }
  let(:payload) { JSON.parse(File.read('spec/fixtures/github/issue_opened.json')) }
  let(:trigger) { create(:trigger, payload: payload) }

  context "with no project in settings" do
    it "does nothing" do
      stub = stub_request(:get, "https://api.github.com/projects/123/columns")
      worker.perform(trigger.id)
      expect(stub).to_not have_been_requested
    end
  end

  context "with a project in settings" do
    context "issue_opened" do
      it "does nothing without matching label" do
        stub_request(:get, "https://api.github.com/projects/123/columns")
          .to_return(:status => 200, :body => File.read('spec/fixtures/github/webmock/columns.json'), :headers => { 'Content-Type' => 'application/json' })

        worker.perform(trigger.id, {
          'projects' => [
            {'id' => 123, 'labels' => ['desktop']}
          ]
        })
      end

      it "adds issue to project with matching label" do
        stub_request(:get, "https://api.github.com/projects/123/columns")
          .to_return(:status => 200, :body => File.read('spec/fixtures/github/webmock/columns.json'), :headers => { 'Content-Type' => 'application/json' })

        stub = stub_request(:post, "https://api.github.com/projects/columns/367/cards")
          .with(:body => "{\"content_type\":\"Issue\",\"content_id\":#{payload['issue']['id']}}")
          .to_return(:status => 201, :body => "", :headers => {})

        worker.perform(trigger.id, {
          'projects' => [
            {'id' => 123, 'labels' => ['bug', 'boop']}
          ]
        })
        expect(stub).to have_been_requested
      end
    end

    context "issue_labeled" do
      let(:payload) { JSON.parse(File.read('spec/fixtures/github/issue_labeled.json')) }
      let(:trigger) { create(:trigger, payload: payload) }

      it "adds issue to project with matching label" do
        stub_request(:get, "https://api.github.com/projects/123/columns")
          .to_return(:status => 200, :body => File.read('spec/fixtures/github/webmock/columns.json'), :headers => { 'Content-Type' => 'application/json' })

        stub = stub_request(:post, "https://api.github.com/projects/columns/367/cards")
          .with(:body => "{\"content_type\":\"Issue\",\"content_id\":#{payload['issue']['id']}}")
          .to_return(:status => 201, :body => "", :headers => {})

        worker.perform(trigger.id, {
          'projects' => [
            {'id' => 123, 'labels' => ['bug', 'boop']}
          ]
        })
        expect(stub).to have_been_requested
      end
    end
  end
end
