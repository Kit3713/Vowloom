class GroupResourcesController < ApplicationController
  before_action :require_live_site!
  before_action :set_group

  def create
    return redirect_to(@group, alert: "Only this group's managers can pin resources.") unless manage_group?

    resourceable = resource_from_key
    return redirect_to(@group, alert: "Choose an event, questionnaire, album, or approved photo/video from this wedding site.") unless resourceable

    resource = @group.group_resources.build(resourceable:, created_by: Current.user)
    if resource.save
      record_audit!("group.resource_pinned", auditable: @group, metadata: resource_metadata(resourceable))
      redirect_to @group, notice: "Resource pinned to this group."
    else
      redirect_to @group, alert: resource.errors.full_messages.to_sentence
    end
  end

  def destroy
    return redirect_to(@group, alert: "Only this group's managers can remove pinned resources.") unless manage_group?

    resource = @group.group_resources.find(params[:id])
    metadata = resource_metadata(resource.resourceable)
    resource.destroy!
    record_audit!("group.resource_unpinned", auditable: @group, metadata:)
    redirect_to @group, notice: "Resource removed from this group."
  end

  private

  def set_group
    @group = current_site.groups.find(params[:group_id])
  end

  def manage_group?
    Current.user.owner? || Current.user.admin? || @group.created_by == Current.user
  end

  def resource_from_key
    type, id = params.dig(:group_resource, :resource_key).to_s.split(":", 2)
    return unless GroupResource::RESOURCE_TYPES.include?(type) && id.to_s.match?(/\A\d+\z/)

    resource = resource_scope(type).find_by(id:)
    resource if resource && GroupResource.new(group: @group, resourceable: resource, created_by: Current.user).visible_to?(Current.user)
  end

  def resource_scope(type)
    {
      "Event" => current_site.events,
      "Questionnaire" => current_site.questionnaires,
      "Album" => current_site.albums,
      "MediaAsset" => current_site.media_assets.approved
    }.fetch(type)
  end

  def resource_metadata(resourceable)
    { resource_type: resourceable.class.name, resource_id: resourceable.id, label: resource_label(resourceable) }
  end

  def resource_label(resourceable)
    case resourceable
    when MediaAsset
      resourceable.caption.presence || resourceable.file.filename.to_s
    else
      resourceable.title
    end
  end
end
