class GroupsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_site

  def index
    redirect_to new_session_path, alert: "Please sign in with your wedding invitation." and return if @site.private_access? && !authenticated?
    @groups = @site.groups.includes(:members).select { |group| group.accessible_to?(Current.user) }
    @group = @site.groups.build
    @available_events = @site.events.select { |event| event.visible_to?(Current.user) }
  end

  def show
    return redirect_to(new_session_path, alert: "Please sign in with your wedding invitation.") if @site.private_access? && !authenticated?

    @group = @site.groups.find(params[:id])
    return redirect_to(groups_path, alert: "That group is private.") unless @group.accessible_to?(Current.user)
    @conversation = @group.posts.visible.find_by(conversation: true) if @group.discussion?
    @posts = @group.posts.visible.where(conversation: false).chronological
    @post = @group.posts.build(space: :group_space, visibility: @group.private_group? ? :members_only : :everyone)
    @available_members = @site.users.order(:display_name) if manage_group?(@group)
    @pinned_resources = @group.group_resources.includes(:resourceable).select { |resource| resource.visible_to?(Current.user) }
    pinned_questionnaire_ids = @pinned_resources.filter_map { |resource| resource.resourceable_id if resource.resourceable_type == "Questionnaire" }
    @group_questionnaires = @group.questionnaires.where.not(status: :draft).reject { |questionnaire| pinned_questionnaire_ids.include?(questionnaire.id) }.select { |questionnaire| questionnaire.available_to?(Current.user) }
    @resource_options = resource_options if manage_group?(@group)
    @task = @group.tasks.build
    @tasks = @group.tasks.includes(:assigned_user, task_comments: :user).order(Arel.sql("completed_at IS NULL DESC"), :due_on, :created_at)
  end

  def create
    require_live_site!
    return redirect_to(groups_path, alert: "Only staff can create groups.") unless staff?
    @group = @site.groups.build(group_params.merge(created_by: Current.user))
    if @group.save
      @group.members << Current.user unless @group.members.include?(Current.user)
      redirect_to @group, notice: "Group created."
    else
      @groups = @site.groups
      @available_events = @site.events.select { |event| event.visible_to?(Current.user) }
      render :index, status: :unprocessable_content
    end
  end

  private

  def set_site
    @site = current_site
    redirect_to new_setup_path and return unless @site
  end

  def staff?
    authenticated? && (Current.user.owner? || Current.user.admin? || Current.user.helper?)
  end

  def group_params
    params.require(:group).permit(:name, :description, :visibility, :participation, :event_id)
  end

  def manage_group?(group)
    authenticated? && (Current.user.owner? || Current.user.admin? || group.created_by == Current.user)
  end

  def resource_options
    pinned = @group.group_resources.pluck(:resourceable_type, :resourceable_id).to_set
    options = []

    @site.events.order(:starts_at, :title).each do |event|
      next unless event.visible_to?(Current.user)
      next if pinned.include?([ "Event", event.id ]) || @group.event_id == event.id

      options << [ "Event — #{event.title}", "Event:#{event.id}" ]
    end
    @site.questionnaires.order(:title).each do |questionnaire|
      next unless questionnaire.available_to?(Current.user) || questionnaire.manageable_by?(Current.user)
      next if pinned.include?([ "Questionnaire", questionnaire.id ])

      options << [ "Questionnaire — #{questionnaire.title}", "Questionnaire:#{questionnaire.id}" ]
    end
    @site.albums.order(:title).each do |album|
      next unless album.everyone? || Current.user.present?
      next if pinned.include?([ "Album", album.id ])

      options << [ "Album — #{album.title}", "Album:#{album.id}" ]
    end
    @site.media_assets.approved.with_attached_file.order(created_at: :desc).each do |media_asset|
      next if pinned.include?([ "MediaAsset", media_asset.id ]) || !media_asset.accessible_to?(Current.user)

      label = media_asset.caption.presence || media_asset.file.filename.to_s
      options << [ "Photo or video — #{label}", "MediaAsset:#{media_asset.id}" ]
    end
    options
  end
end
