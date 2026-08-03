class SetupController < ApplicationController
  class AlreadyInitialized < StandardError; end

  allow_unauthenticated_access
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to new_setup_path, alert: "Please wait before trying setup again." }

  def new
    redirect_to root_path and return if Site.exists?

    prepare_setup_form
  end

  def create
    redirect_to root_path and return if Site.exists?
    @site = Site.new(site_params.except(:banner_image))
    @owner = @site.users.build(owner_params.merge(role: :owner))
    @create_event = starter_params[:create_event] == "1"
    @create_welcome_post = starter_params[:create_welcome_post] == "1"
    @create_gallery_album = starter_params[:create_gallery_album] == "1"
    Time.use_zone(@site.time_zone.presence || "UTC") { @event = @site.events.build(event_params) }

    Site.transaction do
      acquire_initialization_lock!
      raise AlreadyInitialized if Site.exists?

      @site.save!
      @site.banner_image.attach(site_params[:banner_image]) if site_params[:banner_image].present?
      @site.save! if @site.banner_image.attached?
      @owner.save!
      @event.save! if @create_event
      create_starter_content!
      @site.audit_events.create!(actor: @owner, action: "site.initialized", auditable: @site, metadata: setup_audit_metadata)
    end
    start_new_session_for(@owner)
    redirect_to community_path, notice: "Your wedding community is initialized and ready."
  rescue AlreadyInitialized
    redirect_to root_path, alert: "Vowloom was already initialized in another request."
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    prepare_readiness
    render :new, status: :unprocessable_content
  end

  private

  def site_params
    params.require(:site).permit(:name, :wedding_date, :landing_message, :accent_color, :access_policy, :time_zone, :media_quota_gigabytes, :banner_image)
  end

  def owner_params
    params.require(:owner).permit(:display_name, :login_identifier, :recovery_email, :password, :password_confirmation)
  end

  def event_params
    params.fetch(:event, {}).permit(:title, :starts_at, :ends_at, :location_name, :location_address, :map_url, :description, :visibility)
  end

  def starter_params
    params.fetch(:starter, {}).permit(:create_event, :create_welcome_post, :create_gallery_album)
  end

  def prepare_setup_form
    @site ||= Site.new(accent_color: "#8f4f6a", time_zone: "UTC", media_quota_gigabytes: 20)
    @owner ||= User.new
    @event ||= Event.new(title: "Wedding day", visibility: :site_wide)
    @create_event = true if @create_event.nil?
    @create_welcome_post = true if @create_welcome_post.nil?
    @create_gallery_album = true if @create_gallery_album.nil?
    prepare_readiness
  end

  def prepare_readiness
    @readiness = {
      "Database" => ActiveRecord::Base.connection.adapter_name,
      "Media storage" => Rails.application.config.active_storage.service.to_s.humanize,
      "Background jobs" => ActiveJob::Base.queue_adapter.class.name.demodulize.delete_suffix("Adapter"),
      "Email" => ENV["VOWLOOM_SMTP_ADDRESS"].present? ? "Configured" : "Optional — configure later"
    }
  end

  def create_starter_content!
    if @create_welcome_post
      @site.posts.create!(
        user: @owner,
        space: :main,
        visibility: :everyone,
        title: "Welcome",
        body: @site.landing_message.presence || "Welcome to our wedding community. We are glad you are here.",
        pinned: true,
        published_at: Time.current
      )
    end

    return unless @create_gallery_album

    @site.albums.create!(created_by: @owner, title: "Wedding memories", description: "Photos and videos selected for the wedding gallery.", visibility: :everyone, featured: true)
  end

  def setup_audit_metadata
    {
      event_created: @create_event,
      welcome_post_created: @create_welcome_post,
      gallery_album_created: @create_gallery_album,
      access_policy: @site.access_policy,
      time_zone: @site.time_zone
    }
  end

  def acquire_initialization_lock!
    # Vowloom is one wedding per deployment. The transaction-scoped advisory
    # lock prevents two first-run browser submissions from creating two owners.
    Site.connection.execute("SELECT pg_advisory_xact_lock(865_566_662)")
  end
end
