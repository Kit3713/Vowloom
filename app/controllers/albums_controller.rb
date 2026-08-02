class AlbumsController < ApplicationController
  before_action :require_live_site!

  def create
    return redirect_to(gallery_path, alert: "Only staff can create albums.") unless staff?
    album = current_site.albums.build(album_params.merge(created_by: Current.user))
    if album.save
      redirect_to gallery_path, notice: "Album created."
    else
      redirect_to gallery_path, alert: album.errors.full_messages.to_sentence
    end
  end

  private

  def staff?
    Current.user.owner? || Current.user.admin? || Current.user.helper?
  end

  def album_params
    params.require(:album).permit(:title, :description, :visibility)
  end
end
