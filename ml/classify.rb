require 'set'
require 'ankusa'
require 'ankusa/file_system_storage'

file  = 'training.txt'
storage = Ankusa::FileSystemStorage.new(file)
classifier = Ankusa::NaiveBayesClassifier.new(storage)

puts "---"
puts classifier.classifications("Error: TypeError in desktop").inspect
