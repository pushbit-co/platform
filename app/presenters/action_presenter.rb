require "redcarpet"

module Pushbit
  
  class Helpers
    include ViewHelpers
    include DateHelpers
  end
  
  class ActionPresenter
    def initialize(model = nil)
      @model = model
    end
    
    def message
      if File.exist?(template_path)
        template = Tilt.new(template_path)
      else
        template = Tilt.new("./app/views/actions/_default.erb")
      end
      
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: false, disable_indented_code_blocks: true)
      unparsed = template.render(Helpers.new, :action => @model, template_values: template_values)
      markdown.render(unparsed)
    end
    
    def icon
      case @model.kind
        when 'signedup'
          octicon 'heart'
        when 'issue'
          octicon 'issue-opened'
        when 'pull_request'
          octicon 'git-pull-request'
        when 'message'
          "<img class=\"avatar\" src=\"https://avatars2.githubusercontent.com/u/16293997\" />"
        when 'subscribe'
          "<img class=\"avatar\" src=\"#{@model.user.avatar_url}\" />"
        else
          octicon 'comment'
      end
    end
    
    def octicon(icon)
      "<span class=\"octicon octicon-#{icon}\"></span>"
    end
    
    def template_values
      {
        id: id,
        kind: kind,
        task_id: task_id,
        repo_id: repo_id,
        repo_full_name: @model.repo ? @model.repo.github_full_name : nil     
      }
    end
    
    def template_path
      "./app/views/actions/_#{@model.kind}.erb"
    end
    
    def method_missing(method)
      @model.send(method) rescue nil
    end
  end
end