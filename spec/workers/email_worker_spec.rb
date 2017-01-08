require 'spec_helper.rb'

describe "perform" do
  let(:worker) { Pushbit::EmailWorker.new }
  let(:user) { create(:user) }

  context "with a valid email type" do
    it "sends an email" do
      expect(Pony).to receive(:mail)
      worker.perform(:signedup, {:user => user})
    end
  end
end
