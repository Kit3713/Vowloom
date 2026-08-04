class ChatController < ApplicationController
  def show
    redirect_to feed_path("general"), status: :moved_permanently
  end

  def create
    redirect_to feed_path("general"), notice: "General is the wedding-wide conversation now."
  end
end
