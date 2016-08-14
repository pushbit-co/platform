require 'spec_helper.rb'

describe "update repo behavior" do
  let(:repo) { create(:repo, github_id: 123) }
  let(:behavior) { create(:behavior) }

  context "when unauthenticated" do
    it "should redirect to unauthenticated" do
      put "/repos/#{repo.github_full_name}/#{behavior.kind}"
      post "/repos/#{repo.github_full_name}/#{behavior.kind}"
      expect(last_response.status).to eql(302)
    end
  end

  context "when authenticated" do
    context "without existing settings" do
      it "should update the existing settings" do
        post_with_basic_auth "/repos/#{repo.github_full_name}/#{behavior.kind}",
          setting_filter: 'settingvalue'
        expect(last_response.status).to eql(200)
        expect(Pushbit::Setting.last.behavior).to eql(behavior)
      end
    end
  end
end
