module Pushbit
  class Payload
    attr_accessor :data

    def initialize(unparsed_data)
      @data ||= parse_data(unparsed_data)
    end

    def head_sha
      pull_request.fetch('head', {})['sha']
    end

    def head_ref
      pull_request.fetch('head', {})['ref']
    end

    def head_label
      pull_request.fetch('head', {})['label']
    end

    def github_repo_id
      repository['id']
    end

    def full_repo_name
      repository['full_name']
    end

    def pull_request_id
      pull_request['id']
    end

    def pull_request_merged
      pull_request['merged']
    end

    def pull_request_number
      data['number']
    end
    alias_method :number, :pull_request_number

    def action
      data['action']
    end

    def changed_files
      pull_request['changed_files'] || 0
    end

    def ping?
      data['zen']
    end

    def pull_request?
      pull_request.present?
    end

    def repository_owner_id
      repository['owner']['id']
    end

    def repository_owner_name
      repository['owner']['login']
    end

    def build_data
      {
        'number' => pull_request_number,
        'action' => action,
        'pull_request' => {
          'changed_files' => changed_files,
          'head' => {
            'ref' => head_ref,
            'label' => head_label,
            'sha' => head_sha
          }
        },
        'repository' => {
          'id' => github_repo_id,
          'full_name' => full_repo_name,
          'private' => private_repo?,
          'owner' => {
            'id' => repository_owner_id,
            'login' => repository_owner_name,
            'type' => repository['owner']['type']
          }
        }
      }
    end

    def sender_id
      data['sender']['id']
    end

    def issue_id
      data['issue']['id']
    end

    def private_repo?
      repository['private']
    end

    private

    def parse_data(unparsed_data)
      if unparsed_data.is_a? String
        JSON.parse(unparsed_data)
      else
        unparsed_data
      end
    end

    def pull_request
      data.fetch('pull_request', {})
    end

    def repository
      @repository ||= data['repository']
    end
  end
end
