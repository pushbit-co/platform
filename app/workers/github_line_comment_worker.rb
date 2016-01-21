module Pushbit
  class GithubLineCommentWorker < BaseWorker
    def work(task_id)
      task = Task.find(task_id)
      comments = {}

      Octokit.auto_paginate = true
      changed_files = client.pull_request_files(
        task.repo.github_full_name,
        task.trigger.payload["number"]
      )

      # Group discoveries by the line that they are on so we can combine
      # them into a single comment when it makes sense
      task.discoveries.unactioned.each do |discovery|
        file = changed_files.find { |f| f[:filename] == discovery.path }

        if file
          patch = Patch.new(file[:patch])
          line = patch.changed_lines.find { |l| l.number == discovery.line }

          if line
            if comments[line.patch_position]

              # If the same issue occurs twice on same line, only list it once
              unless comments[line.patch_position].discoveries.find { |d| d.message == discovery.message }
                comments[line.patch_position].discoveries << discovery
              end
            else
              comments[line.patch_position] = LineComment.new(discoveries: [discovery], line: line, file: file)
            end
          else
            puts "#{file[:filename]} in changed files and discoveries but no matching lines"
          end
        else
          puts "#{file[:filename]} in discoveries but not in changed files"
        end
      end

      comments.each do |_index, comment|
        response = client.create_pull_request_comment(
          task.repo.github_full_name,
          task.trigger.payload["number"],
          comment.message(task),
          task.trigger.payload["pull_request"]["head"]["sha"],
          comment.file.filename,
          comment.line.patch_position
        )

        action = Action.create!({
                                  kind: 'line_comment',
                                  body: comment.message(task),
                                  repo_id: task.repo_id,
                                  task_id: task.id,
                                  github_id: response.id,
                                  github_url: response.html_url
                                }, without_protection: true)

        comment.discoveries.each do |discovery|
          discovery.update_attribute(:action_id, action.id)
        end
      end
    end
  end
end
