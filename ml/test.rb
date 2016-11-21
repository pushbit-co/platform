require 'set'
require 'ankusa'
require 'ankusa/file_system_storage'

file  = './ml/issue-label-training.txt'
storage = Ankusa::FileSystemStorage.new(file)
classifier = Ankusa::NaiveBayesClassifier.new(storage)

tests = [
  "Show spinner on commit form",
  "Error: Attempting to call a function in a renderer window that has been closed or released",
  "Errors an unexpected behavior when viewing a project whilst it is deleted",
  "Persistent Plugin Problem",
  "Make invite people button more prominent",
  "Update organization invitation screen VD",
  "Error: Cannot locate local branch '<UUID>'",
  "Add markdown helper to comment form",
  "Feature: Logger",
  "XSS exploit on login form",
  "Document new API endpoints"
]

tests.each do |title|
  puts "title: #{title}"
  puts "label: #{classifier.classify(title)}"
  puts "---"
end
