require 'zlib'
require 'yajl'
require 'set'
require 'ankusa'
require 'ankusa/file_system_storage'

file  = './ml/issue-label-training.txt'
storage = Ankusa::FileSystemStorage.new(file)
classifier = Ankusa::NaiveBayesClassifier.new(storage)
allowable = ['bug', 'enhancement', 'feature', 'question', 'discussion', 'help wanted']

correct_count = 0
uncorrect_count = 0

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

        #if (allowable & labels).size > 0
        classifications = classifier.classifications(title)
        chosen = classifications.sort_by { |k,v| v }.last
        chosen_label = chosen.first

        if labels.include?(chosen_label)
          correct_count += 1
          puts "CORRECT MATCH #{chosen_label} (#{chosen.last}): #{title}"
        elsif chosen.last < 0.5
          puts "CORRECT NOMATCH #{chosen_label} (#{chosen.last}): #{title}"
          correct_count += 1
        else
          uncorrect_count += 1
          puts "MISSED MATCH #{chosen_label} (#{chosen.last}): #{title}"
        end
        #end
      end
    end
  end
end

puts "#{correct_count} / #{uncorrect_count} matched"
