class TaskCommentsController < ApplicationController
  before_action :require_live_site!
  before_action :set_group_and_task

  def create
    return redirect_to(@group, alert: "Sign in to comment on a task.") unless authenticated?
    return redirect_to(@group, alert: "You cannot comment on this task.") unless @group.accessible_to?(Current.user)

    comment = @task.task_comments.build(user: Current.user, body: params.require(:task_comment).fetch(:body))
    if comment.save
      redirect_to @group, notice: "Task comment added."
    else
      redirect_to @group, alert: comment.errors.full_messages.to_sentence
    end
  end

  private

  def set_group_and_task
    @group = current_site.groups.find(params[:group_id])
    @task = @group.tasks.find(params[:task_id])
  end
end
