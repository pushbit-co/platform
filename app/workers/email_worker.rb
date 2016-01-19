module Pushbit
  class EmailWorker < BaseWorker
    def work(type, user_id)
      Mailer.mail(type, user_id)
    end
  end
end