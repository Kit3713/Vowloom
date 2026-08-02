class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @site = Site.first
  end
end
