module Pushbit
  class Helpers
    include ViewHelpers
  end
  
  class LineComment
    attr_reader :discoveries, :line, :file

    def initialize(discoveries:, line:, file:)
      @discoveries = discoveries
      @line = line
      @file = file
    end
    
    def message(task)
      helpers = Helpers.new

      if discoveries.length > 1
        output = "A couple of #{helpers.pluralize(2, task.behavior.discovers)} on this line\n\n"
        
        discoveries.each do |discovery|
          output += (discovery.message || discovery.title) + "\n"
        end
        
        output
      else
        discoveries.first.message || discoveries.first.title
      end
    end
  end
end
