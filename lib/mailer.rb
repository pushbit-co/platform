module Pushbit
  class Mailer
    class << self
      def mail(type, data)
        begin
          template = Tilt.new("./app/views/mailers/#{type}.text.erb")
          message = template.render(self, data)
        rescue Errno::ENOENT => e
          raise MailerError.new("Email template #{type} not available")
        end

        puts "IDENT HERE"
        puts data.keys.inspect
        puts "IDENT MESSAGE"
        puts message.inspect
        puts "IDENT USER"
        puts data["user"].inspect

        if respond_to? type
          Pony.mail(send(type, message, data))
        else
          fail MailerError.new("Email method #{type} not available")
        end
      end

      def signedup(message, data)
        {
          to: data[:user].email,
          subject: "Welcome to Pushbit",
          body: message
        }
      end

      def reminder(message, data)
        {
          to: data[:user].email,
          subject: "You have stale issues",
          body: message
        }
      end
    end
  end
end
