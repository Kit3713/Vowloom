class RegistryCollectionsController < ApplicationController
  allow_unauthenticated_access only: :index
  before_action :set_site

  def index
    redirect_to new_session_path, alert: "Please sign in with your wedding invitation." and return if @site.private_access? && !authenticated?
    @collections = @site.registry_collections.where(published: true)
    @collections = @collections.where(visibility: :everyone) unless authenticated?
    @collection = @site.registry_collections.build
    @my_claims = authenticated? ? RegistryClaim.joins(registry_item: :registry_collection).where(user: Current.user, registry_collections: { site_id: @site.id }).index_by(&:registry_item_id) : {}
    @staff_claims = site_manager? ? RegistryClaim.joins(registry_item: :registry_collection).where(registry_collections: { site_id: @site.id }).includes(:user, registry_item: :registry_collection).order(created_at: :desc) : []
  end

  def update
    require_live_site!
    return if @site.content_frozen?

    return redirect_to(registry_collections_path, alert: "Only staff can manage the registry.") unless staff?

    @collection = @site.registry_collections.find(params[:id])
    if @collection.update(collection_params)
      record_audit!("registry_collection_updated", auditable: @collection)
      redirect_to registry_collections_path, notice: "Registry collection updated."
    else
      redirect_to registry_collections_path, alert: @collection.errors.full_messages.to_sentence
    end
  end

  def create
    require_live_site!
    return redirect_to(registry_collections_path, alert: "Only staff can manage the registry.") unless staff?
    @collection = @site.registry_collections.build(collection_params.merge(published: true))
    if @collection.save
      redirect_to registry_collections_path, notice: "Registry collection created."
    else
      @collections = @site.registry_collections.where(published: true)
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

  def site_manager?
    authenticated? && (Current.user.owner? || Current.user.admin?)
  end

  def collection_params
    params.require(:registry_collection).permit(
      :title, :description, :visibility, :published,
      :external_registry_url, :charity_url, :cash_fund_url
    )
  end
end
