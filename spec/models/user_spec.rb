require 'spec_helper'

describe Pushbit::User do
  describe "save" do
    context "without github_id" do
      let(:user) { create(:user, github_id: nil) }

      it "is invalid" do
        expect { user.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "without login" do
      let(:user) { create(:user, login: nil) }

      it "is invalid" do
        expect { user.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "with all attributes" do
      let(:user) { create(:user, github_id: 123, login: 'yahyahyah', email: 'yah@yah.com') }

      it "sends a welcome email" do
        user.save!
        expect(Pushbit::EmailWorker.jobs.length).to eql(1)
      end
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
