module Pushbit
  module ViewHelpers

    def nav_link(path, title)
      className = request.path_info == path ? 'active' : ''
      "<a href=\"#{path}\" class=\"#{className}\">#{title}</a>"
    end

    def readable(time)
      "#{distance_of_time_in_words(time.to_i, Time.now.to_i, true)} ago"
    end

    def signup_button
      unless current_user
        "<a href=\"/auth/login\" class=\"btn btn-primary btn-block\">Sign up</a>"
      end
    end

    def greeting
      [
        "Hey there",
        "Howdy",
        "Howdy :wave:",
        "Hello again",
        "Hey :wave:",
        "Hey team"
      ].sample
    end

    def signoff
      [
        "Hope this helps",
        "Merge away if useful :shipit:",
        "I hope this is useful :smile:"
      ].sample
    end

    def tasks_duration_in_minutes(tasks)
      (tasks.map(&:duration).inject(:+) / 60).ceil if tasks.length > 0
    end

    def readable_header(date)
      today = DateTime.now.yday

      if date.yday == today
        "Today"
      elsif date.yday + 1 == today
        "Yesterday"
      elsif date.yday + 6 <= today
        date.strftime("%A")
      else
        date.strftime("%A, %b %d")
      end
    end

    def pluralize(count, singular, plural = nil)
      if count == 1 || count =~ /^1(\.0+)?$/
        singular
      else
        plural || singular.pluralize
      end
    end

    def partial(template, *args)
      template_array = template.to_s.split('/')
      template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
      options = args.last.is_a?(Hash) ? args.pop : {}
      options.merge!(layout: false)
      locals = options[:locals] || {}

      if collection = options.delete(:collection)
        collection.inject([]) do |buffer, member|
          buffer << erb(:"#{template}", options.merge(layout:           false, locals: { template_array[-1].to_sym => member }.merge(locals)))
        end.join("\n")
      else
        erb(:"#{template}", options)
      end
    end
  end
end
