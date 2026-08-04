class CalendarsController < ApplicationController
  allow_unauthenticated_access

  def show
    redirect_to events_path(month: params[:month]), status: :moved_permanently
  end
end
