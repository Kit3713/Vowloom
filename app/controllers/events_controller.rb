class EventsController < ApplicationController
  allow_unauthenticated_access only: %i[index show calendar]
  before_action :set_site

  def index
    redirect_to new_session_path, alert: "Please sign in with your wedding invitation." and return if @site.private_access? && !authenticated?
    @events = @site.events.order(:starts_at).select { |event| event.visible_to?(Current.user) }
    @event = @site.events.build
    @month = requested_month || @site.wedding_date&.beginning_of_month || Date.current.beginning_of_month
    @events_by_date = @events.select { |event| event.starts_at.present? }.group_by { |event| event.starts_at.to_date }
    @weeks = ((@month.beginning_of_month.beginning_of_week(:sunday))..(@month.end_of_month.end_of_week(:sunday))).to_a.each_slice(7)
  end

  def show
    return redirect_to(new_session_path, alert: "Please sign in with your wedding invitation.") if @site.private_access? && !authenticated?

    @event = @site.events.find(params[:id])
    redirect_to events_path, alert: "That event is private." and return unless @event.visible_to?(Current.user)
    @available_invitees = @site.invitees.order(:last_name, :first_name) if site_manager?
    @household_invitations = household_invitations_for_current_user
    @event_history = event_history if site_manager?
  end

  def create
    require_live_site!
    return if performed?
    return redirect_to(events_path, alert: "Only staff can create events.") unless staff?

    @event = @site.events.build(event_params)
    if @event.save
      record_audit!("event.created", auditable: @event, metadata: event_details(@event))
      redirect_to @event, notice: "Event created."
    else
      @events = @site.events.order(:starts_at)
      render :index, status: :unprocessable_content
    end
  end

  def update
    require_live_site!
    return if performed?
    return redirect_to(events_path, alert: "Only staff can edit events.") unless staff?

    @event = @site.events.find(params[:id])
    if @event.update(event_params)
      record_audit!("event.updated", auditable: @event, metadata: changed_fields(@event))
      redirect_to @event, notice: "Event updated."
    else
      @available_invitees = @site.invitees.order(:last_name, :first_name) if site_manager?
      @household_invitations = household_invitations_for_current_user
      @event_history = event_history if site_manager?
      render :show, status: :unprocessable_content
    end
  end

  def destroy
    require_live_site!
    return if performed?
    return redirect_to(events_path, alert: "Only staff can delete events.") unless staff?

    @event = @site.events.find(params[:id])
    record_audit!("event.deleted", auditable: @event, metadata: event_details(@event))
    @event.destroy!
    redirect_to events_path, notice: "Event deleted."
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

  def requested_month
    return if params[:month].blank?

    Date.strptime(params[:month], "%Y-%m").beginning_of_month
  rescue ArgumentError
    nil
  end

  def staff?
    authenticated? && (Current.user.owner? || Current.user.admin? || Current.user.helper?)
  end

  def site_manager?
    authenticated? && (Current.user.owner? || Current.user.admin?)
  end

  def event_params
    params.require(:event).permit(:title, :description, :starts_at, :ends_at, :rsvp_deadline, :location_name, :location_address, :map_url, :visibility, :meal_options_text)
  end

  def changed_fields(event)
    { changed_fields: event.previous_changes.except("updated_at").keys, title: event.title }
  end

  def event_details(event)
    {
      title: event.title,
      starts_at: event.starts_at,
      rsvp_deadline: event.rsvp_deadline,
      visibility: event.visibility
    }
  end

  def event_history
    @site.audit_events.where(auditable: @event).includes(:actor).order(created_at: :desc).limit(50)
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
