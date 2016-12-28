desc "Runs periodically"
task :cron do 
  sleep 6 
  b = Pushbit::Behavior.find_by!(kind:"issue_reminder")
  client ||= Octokit::Client.new(:access_token => ENV.fetch("GITHUB_TOKEN"))

  Pushbit::User.all.each do |user|
    puts user.inspect
    if b.repos.joins(:users).where(["users.id = ?", user.id]).count > 0 
      # Pushbit::IssueReminderWorker.perform_async(user.id)
      Pushbit::IssueReminderWorker.new.perform(user.id)
    end
  end
end
