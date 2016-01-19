require 'spec_helper'

describe Pushbit::Mailer do
  let(:user) { create(:user) }

  describe "signedup" do
    it "sends an email" do
      expect(Pony).to receive(:mail) do |options|
        expect(options[:to]).to eql(user.email)
        expect(options[:subject]).to eql("Welcome to Pushbit")
      end

      Pushbit::Mailer.mail(:signedup, user.id)
    end
  end
end