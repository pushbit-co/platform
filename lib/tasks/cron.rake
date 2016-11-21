desc "Runs periodically"
task :cron do 
  Pushbit::User.all.each do |user|
    user.repos.each do |repo|
      puts "IDENT INSPECT"
      puts repo.inspect
      puts "BEHAVIOR INSPECT"
      puts repo.behaviors.trigger(:cron).count.inspect
    end
  end
end
