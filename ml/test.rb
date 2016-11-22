require 'zlib'
require 'yajl'
require 'set'
require 'ankusa'
require 'ankusa/file_system_storage'

file  = './ml/issue-label-training.txt'
storage = Ankusa::FileSystemStorage.new(file)
classifier = Ankusa::NaiveBayesClassifier.new(storage)
allowable = ['bug', 'enhancement', 'feature', 'question', 'discussion', 'help wanted', 'security']

match_count = 0
unmatch_count = 0

Dir.foreach('./ml/testing') do |item|
  next if item == '.' or item == '..'
  # do work on real items

  gz = File.open("./ml/testing/#{item}")
  js = Zlib::GzipReader.new(gz).read
  parser = Yajl::Parser.new

  parser.parse(js) do |event|
    if event['type'] == 'IssuesEvent'
      if event['payload']['action'] == 'opened'
        labels = event['payload']['issue']['labels'].map { |label| label['name'].downcase.gsub(/[^a-z ]/i, '').strip }
        title = event['payload']['issue']['title']

        if (allowable & labels).size > 0
          chosen_label = classifier.classify(title)

          if labels.include?(chosen_label)
            match_count += 1
            puts "MATCH #{chosen_label}: #{title}"
          else
            unmatch_count += 1
            puts "NO MATCH #{chosen_label}: #{title}"
          end
        end
      end
    end
  end
end

puts "#{match_count} / #{unmatch_count} matched"
