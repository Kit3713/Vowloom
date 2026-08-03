class RegistryItemsController < ApplicationController
  before_action :require_live_site!

  def create
    collection = current_site.registry_collections.find(params[:registry_collection_id])
    return redirect_to(registry_collections_path, alert: "Only staff can add registry items.") unless staff?

    item = collection.registry_items.build(item_params)
    if item.save
      record_audit!("registry_item_created", auditable: item, metadata: { collection_id: collection.id })
      redirect_to registry_collections_path, notice: "Registry item added."
    else
      redirect_to registry_collections_path, alert: item.errors.full_messages.to_sentence
    end
  end

  def update
    item = RegistryItem.joins(:registry_collection).where(registry_collections: { site_id: current_site.id }).find(params[:id])
    return redirect_to(registry_collections_path, alert: "Only staff can manage registry items.") unless staff?

    if item.update(item_params)
      record_audit!("registry_item_updated", auditable: item)
      redirect_to registry_collections_path, notice: "Registry item updated."
    else
      redirect_to registry_collections_path, alert: item.errors.full_messages.to_sentence
    end
  end

  private

  def staff?
    Current.user.owner? || Current.user.admin? || Current.user.helper?
  end

  def item_params
    params.require(:registry_item).permit(
      :title, :description, :external_url, :currency, :price_cents, :quantity_requested,
      :priority, :category, :published, :image
    )
  end
end
