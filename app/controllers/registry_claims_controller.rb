class RegistryClaimsController < ApplicationController
  before_action :require_live_site!

  def create
    item = RegistryItem.joins(:registry_collection).where(registry_collections: { site_id: current_site.id }).find(params[:registry_item_id])
    claim = item.claim!(Current.user, quantity: params.fetch(:quantity, 1).to_i)
    redirect_to registry_collections_path, notice: "You reserved #{claim.quantity} of #{item.title}."
  rescue ActiveRecord::RecordInvalid
    redirect_to registry_collections_path, alert: "That quantity is no longer available."
  end

  def update
    claim = RegistryClaim.joins(registry_item: :registry_collection).where(registry_collections: { site_id: current_site.id }).find(params[:id])
    if site_manager?
      claim.update!(staff_claim_params)
      claim.update!(received_at: Time.current) if params[:mark_received] == "1" && claim.received_at.blank?
      claim.update!(thank_you_sent_at: Time.current) if params[:mark_thank_you_sent] == "1" && claim.thank_you_sent_at.blank?
      claim.update!(purchaser_revealed_at: Time.current) if params[:reveal_purchaser] == "1" && claim.purchaser_revealed_at.blank?
      record_audit!("registry_gift_tracking_updated", auditable: claim, metadata: { claim_id: claim.id })
      return redirect_to(registry_collections_path, notice: "Gift tracking updated.")
    end

    return redirect_to(registry_collections_path, alert: "You can only update your own registry claim.") unless claim.user == Current.user

    status = member_claim_params.fetch(:status)
    return redirect_to(registry_collections_path, alert: "Choose Purchased or Released.") unless status.in?(%w[purchased released])

    claim.update!(status:, purchased_at: status == "purchased" ? Time.current : nil)
    redirect_to registry_collections_path, notice: "Registry claim updated."
  end

  private

  def site_manager?
    Current.user.owner? || Current.user.admin?
  end

  def member_claim_params
    params.require(:registry_claim).permit(:status)
  end

  def staff_claim_params
    params.fetch(:registry_claim, {}).permit(:private_note)
  end
end
