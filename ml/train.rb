require 'zlib'
require 'yajl'
require 'set'
require 'ankusa'
require 'ankusa/file_system_storage'

# we need to whitelist labels that the bot is willing to add - after all, we
# don't want it to start labelling things invalid or wontfix!
allowable = ['bug', 'enhancement', 'feature', 'question', 'discussion', 'help wanted', 'security']
file = './ml/issue-label-training.txt'

File.delete(file) if File.exists?(file)

storage = Ankusa::FileSystemStorage.new(file)
classifier = Ankusa::NaiveBayesClassifier.new(storage)
counts = Hash.new 0

Dir.foreach('./ml/corpus') do |item|
  next if item == '.' or item == '..'
  # do work on real items

  gz = File.open("./ml/corpus/#{item}")
  js = Zlib::GzipReader.new(gz).read
  parser = Yajl::Parser.new

  parser.parse(js) do |event|
    if event['type'] == 'IssuesEvent'
      if event['payload']['action'] == 'opened'
        if event['payload']['issue']['labels'].size > 0
          labels = event['payload']['issue']['labels'].map { |label| label['name'].downcase.gsub(/[^a-z ]/i, '').strip }
          title = event['payload']['issue']['title']

          labels.each do |label|
            unless label.empty?
              if allowable.include? label
                counts[label] += 1

                puts "Adding to training set (#{label}) #{title}"
                classifier.train(label, title)
              else
                puts "Adding to training set (none) #{title}"
                classifier.train('none', title)
              end
            end
          end
        end
      end
    end
  end
end


puts "label counts"
puts counts.inspect

puts "saving model…"
storage.save
