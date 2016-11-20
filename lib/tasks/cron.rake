desc "Runs periodically"
task :cron do 
  Pushbit::User.all.each do |user|
    user.repos.each do |repo|
      puts repo.inspect
    end
  end
end
