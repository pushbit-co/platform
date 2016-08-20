module Pushbit
  class RepoSyncronizationWorker < BaseWorker

    def work(user_id)
      puts "YOPP"
      Octokit.auto_paginate = true

      # clear any existing memberships as we may have been removed as well as 
      # added to repositories since the last sync
      user = User.find(user_id)
      user.repos.clear

      Repo.transaction do
        user.client.repositories.each do |data|
          puts "IDENTX"
          puts data

          repo = Repo.find_or_create_with({
            private: data.private,
            default_branch: data.default_branch,
            github_id: data.id,
            github_full_name: data.full_name,
            tags: [data.language]
          }, {
            github_id: data.owner[:id],
            name: data.owner[:login],
            organization: data.owner[:type] == "Organization"
          })

          user.repos << repo
        end
      end

      user.syncing = false
      user.last_synchronized_at = DateTime.now
      user.save!
    end
  end
end
