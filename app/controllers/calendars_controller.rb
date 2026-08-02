class CalendarsController < ApplicationController
  allow_unauthenticated_access

  def show
    @site = current_site
    redirect_to new_setup_path and return unless @site
    redirect_to new_session_path, alert: "Please sign in with your wedding invitation." and return if @site.private_access? && !authenticated?

    @month = requested_month || @site.wedding_date&.beginning_of_month || Date.current.beginning_of_month
    @events = @site.events.order(:starts_at).select { |event| event.visible_to?(Current.user) }
    @events_by_date = @events.select { |event| event.starts_at.present? }.group_by { |event| event.starts_at.to_date }
    @weeks = ((@month.beginning_of_month.beginning_of_week(:sunday))..(@month.end_of_month.end_of_week(:sunday))).to_a.each_slice(7)
  end

  private

  def requested_month
    return if params[:month].blank?

    Date.strptime(params[:month], "%Y-%m").beginning_of_month
  rescue ArgumentError
    nil
  end
end
