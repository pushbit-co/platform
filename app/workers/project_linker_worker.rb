# settings are in the format:
# {projects: [
#   {id: 123, labels: ['desktop']},
#   {id: 456, labels: ['mac']}
# ]}

module Pushbit
  class ProjectLinkerWorker < BaseWorker
    def work(trigger_id, settings = {})
      trigger = Trigger.find(trigger_id)
      payload = trigger.payload
      labels = payload['issue']['labels'].map { |l| l['name'] }

      # No labels or settings? We aint linking anything here then
      return if labels.size == 0
      return if settings['projects'].nil?

      # Handle multiple project / label links
      settings['projects'].each do |opts|
        # Issue is always added into the first column for now
        columns = client.project_columns(opts['id'])
        column_id = columns.first.id

        should_be_in_project = labels.any? {|label| opts['labels'].include?(label) }
        puts 'should_be_in_project'
        puts should_be_in_project

        if should_be_in_project
          client.create_project_card(column_id, {
            content_type: 'Issue',
            content_id: payload['issue']['id']
          })
        end
      end
    end
  end
end
