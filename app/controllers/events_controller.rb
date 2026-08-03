class EventsController < ApplicationController
  allow_unauthenticated_access only: %i[index show calendar]
  before_action :set_site

  def index
    redirect_to new_session_path, alert: "Please sign in with your wedding invitation." and return if @site.private_access? && !authenticated?
    @events = @site.events.order(:starts_at).select { |event| event.visible_to?(Current.user) }
    @event = @site.events.build
  end

  def show
    return redirect_to(new_session_path, alert: "Please sign in with your wedding invitation.") if @site.private_access? && !authenticated?

    @event = @site.events.find(params[:id])
    redirect_to events_path, alert: "That event is private." and return unless @event.visible_to?(Current.user)
    @available_invitees = @site.invitees.order(:last_name, :first_name) if site_manager?
    @household_invitations = household_invitations_for_current_user
  end

  def create
    require_live_site!
    return redirect_to(events_path, alert: "Only staff can create events.") unless staff?

    @event = @site.events.build(event_params)
    if @event.save
      redirect_to @event, notice: "Event created."
    else
      @events = @site.events.order(:starts_at)
      render :index, status: :unprocessable_content
    end
  end

  def calendar
    return redirect_to(new_session_path, alert: "Please sign in with your wedding invitation.") if @site.private_access? && !authenticated?

    @event = @site.events.find(params[:id])
    return redirect_to(events_path, alert: "That event is private.") unless @event.visible_to?(Current.user)

    send_data calendar_content(@event), filename: "#{@event.title.parameterize.presence || 'event'}.ics", type: "text/calendar", disposition: "attachment"
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

  def event_params
    params.require(:event).permit(:title, :description, :starts_at, :ends_at, :location_name, :location_address, :map_url, :visibility, :meal_options_text)
  end

  def calendar_content(event)
    lines = [
      "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Vowloom//EN", "BEGIN:VEVENT",
      "UID:vowloom-event-#{event.id}@#{request.host}", "DTSTAMP:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}",
      "DTSTART:#{calendar_time(event.starts_at)}", "DTEND:#{calendar_time(event.ends_at || event.starts_at)}",
      "SUMMARY:#{calendar_text(event.title)}", "LOCATION:#{calendar_text([ event.location_name, event.location_address ].compact_blank.join(', '))}",
      "DESCRIPTION:#{calendar_text(event.description)}", "END:VEVENT", "END:VCALENDAR", ""
    ]
    lines.join("\r\n")
  end

  def calendar_time(time)
    time&.utc&.strftime("%Y%m%dT%H%M%SZ") || Time.current.utc.strftime("%Y%m%dT%H%M%SZ")
  end

  def calendar_text(value)
    value.to_s.gsub(/([,;\\])/, '\\\\\1').gsub(/\r?\n/, "\\n")
  end

  def household_invitations_for_current_user
    household = Current.user&.invitee&.household
    return [] unless household

    @event.event_invitations.includes(:invitee).where(invitees: { household_id: household.id }).joins(:invitee).order("invitees.last_name", "invitees.first_name")
  end
end
