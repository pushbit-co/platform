module Pushbit
  class Behavior < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity

    default_scope -> { order('active DESC') }

    scope :any_tags, -> (tags) { where('tags && ARRAY[?]::varchar[]', tags) }
    scope :all_tags, -> (tags) { where('tags @> ARRAY[?]::varchar[]', tags) }
    scope :trigger, -> (trigger) { where('triggers @> ARRAY[?]::varchar[]', trigger) }

    has_many :repos, through: :repo_behaviors
    has_many :tasks

    def execute!(trigger_id)
      worker_class.perform_async trigger_id
    end

    def worker_class
      Object.const_get "Pushbit::#{kind.split("_").map(&:capitalize).join("")}Worker"
    end

    def self.active
      where(active: true)
    end

    def self.find_or_create_with(attributes)
      behave = find_by(kind: attributes["kind"]) || Behavior.new
      attributes = attributes.select do |k, _v|
        columns = Behavior.columns.map { |c| c.name.to_sym }
        columns.include? k.to_sym
      end
      behave.update_attributes(attributes, without_protection: true)
      behave
    end

    def matches_files?(changed_files)
      run = false
      return true if !files || files.length == 0

      changed_files.each do |changed|
        files.each do |pattern|
      	  run = true if changed.match(pattern)
        end
      end

      run
    end
  end
end
