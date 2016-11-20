require 'open-uri'
require 'zlib'
require 'yajl'
require 'set'
require 'ankusa'
require 'ankusa/file_system_storage'

file  = 'training.txt'
storage = Ankusa::FileSystemStorage.new(file)
classifier = Ankusa::NaiveBayesClassifier.new(storage)
allowable = ['bug', 'enhancement', 'feature']

days = (1..30).to_a
hours = (0..23).to_a

days.each do |day|
  day = sprintf '%02d', day

  hours.each do |hour|
    url = "http://data.githubarchive.org/2016-01-#{day}-#{hour}.json.gz"
    puts "opening: #{url}"
    gz = open(url)
    js = Zlib::GzipReader.new(gz).read
    parser = Yajl::Parser.new

    parser.parse(js) do |event|
      if event['type'] == 'IssuesEvent'
        if event['payload']['action'] == 'opened'
          if event['payload']['issue']['labels'].size > 0
            labels = event['payload']['issue']['labels'].map { |label| label['name'].downcase! }

            labels.each do |label|
              if allowable.include?(label)
                puts "Adding to training set (#{label}) #{event['payload']['issue']['title']}"
                classifier.train(label, event['payload']['issue']['title'])
              end
            end
          end
        end
      end
    end
  end
end

puts "saving model…"
storage.save
