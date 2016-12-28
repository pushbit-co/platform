module Pushbit
  class IssueReminderWorker < BaseWorker

    def work(user_id)
      user = User.find(user_id)
      issues = {}

      b = Pushbit::Behavior.find_by!(kind:"issue_reminder")

      b.repos.joins(:users).where(["users.id = ?", user.id]).all.each do |r|
        client.list_issues(r.github_full_name).each do |i|

          t = i.pull_request.nil? ? "issue" : "PR"

          cs = client.issue_comments(r.github_full_name, i['number'])
          cs = cs.reject { i.user[:login] == "pushbit-bot" }

          last_updated_at = i.created_at

          if cs.length > 0 
            last_updated_at = cs.last.created_at
          end

          if i['created_at'] < 60.days.ago
            client.add_comment(
              r.github_full_name, 
              i['number'], 
              "We've closed this #{t} due to inactivity"
            )
            client.close_issue(r.github_full_name, i['number'])
            Task.create!({
              action: "close",
              behavior: "issue_reminder",
              github_id: i['number'],
              repo_id: r.id
            })
            next
          end

          next if Task.where({
            action: "remind",
            behavior: "issue_reminder",
            github_id: i['number'],
            repo_id: r.id
          }).count > 0 

          if last_updated_at < 20.days.ago
            client.add_comment(
              r.github_full_name, 
              i['number'], 
              "We've noticed this #{t} hasn't been active in a while, we will close this issue soon. Just add a comment and we'll leave it alone"
            )

            Task.create!({
              action: "remind",
              behavior: "issue_reminder",
              github_id: i['number'],
              repo_id: r.id
            })
          end
        end
      end
    end
  end
end
