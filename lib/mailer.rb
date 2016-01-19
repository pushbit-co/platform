module Pushbit
  class Mailer
    class << self
      def mail(type, user_id)
        user = User.find(user_id)

        begin
          template = Tilt.new("./app/views/mailers/#{type}.text.erb")
          message = template.render(self, user: user)
        rescue Errno::ENOENT => e
          raise MailerError.new("Email template #{type} not available")
        end

        if respond_to? type
          Pony.mail(send(type, message, user))
        else
          fail MailerError.new("Email method #{type} not available")
        end
      end

      def signedup(message, user)
        {
          to: user.email,
          subject: "Welcome to Pushbit",
          body: message
        }
      end
    end
  end
end