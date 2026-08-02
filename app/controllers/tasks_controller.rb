class TasksController < ApplicationController
  before_action :require_live_site!
  before_action :set_group

  def create
    return redirect_to(@group, alert: "Only group managers can create tasks.") unless manage_group?

    task = @group.tasks.build(task_params)
    if task.save
      redirect_to @group, notice: "Task added."
    else
      redirect_to @group, alert: task.errors.full_messages.to_sentence
    end
  end

  def update
    task = @group.tasks.find(params[:id])
    return redirect_to(@group, alert: "Only group managers can update tasks.") unless manage_group?

    task.update!(completed_at: task.complete? ? nil : Time.current)
    redirect_to @group, notice: task.complete? ? "Task marked complete." : "Task reopened."
  end

  private

  def set_group
    @group = current_site.groups.find(params[:group_id])
  end

  def manage_group?
    Current.user.owner? || Current.user.admin? || @group.created_by == Current.user
  end

  def task_params
    params.require(:task).permit(:title, :description, :due_on, :assigned_user_id)
  end
end
