require 'spec_helper'

describe Pushbit::User do
  describe "save" do
    it "is invalid without github_id" do
      user = Pushbit::User.new(login: 'yahyahyah')
      expect { user.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "is invalid without login" do
      user = Pushbit::User.new(github_id: 123)
      expect { user.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "sends a welcome email" do
      user = Pushbit::User.new({ github_id: 123, login: 'yahyahyah', email: 'yah@yah.com' }, without_protection: true)
      user.save!
      expect(Pushbit::EmailWorker.jobs.length).to eql(1)
    end
  end

  describe "first_name" do
    context "with name" do
      let(:user) { create(:user, name: 'Joe Bloggs') }
      it "returns first name" do
        expect(user.first_name).to eql('Joe')
      end
    end

    context "without name" do
      let(:user) { create(:user, name: nil) }
      it "returns first name" do
        expect(user.first_name).to eql(nil)
      end
    end
  end

  describe "find_or_create_with" do
    it "does not create duplicate users" do
      Pushbit::User.find_or_create_with(github_id: 123, login: 'lordelorde')
      Pushbit::User.find_or_create_with(github_id: 123, login: 'lordelorde')
      expect(Pushbit::User.count).to eql(1)
    end

    it "does not clear repo memberships" do
      user = Pushbit::User.find_or_create_with(github_id: 123, login: 'lordelorde')
      user.repos << Pushbit::Repo.new(github_id: 123)

      Pushbit::User.find_or_create_with(github_id: 123)
      expect(user.repos.count).to eql(1)
    end

    it "clears repo memberships when scopes are reduced" do
      user = Pushbit::User.find_or_create_with(github_id: 123, login: 'lordelorde')
      user.repos << Pushbit::Repo.new(github_id: 123, private: true)
      user.repos << Pushbit::Repo.new(github_id: 456)

      Pushbit::User.find_or_create_with(github_id: 123, token: 'abc', token_scopes: 'user')
      expect(user.repos.count).to eql(0)
    end

    it "does not clear public repo memberships when token_scopes changes" do
      user = Pushbit::User.find_or_create_with(github_id: 123, login: 'lordelorde')
      user.repos << Pushbit::Repo.new(github_id: 123, private: false)

      Pushbit::User.find_or_create_with(github_id: 123, token: 'def', token_scopes: 'repo')
      expect(user.repos.count).to eql(1)
    end
  end
end