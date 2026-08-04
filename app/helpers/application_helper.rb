module ApplicationHelper
  SOCIAL_SHELL_EXCLUSIONS = %w[home setup sessions registrations passwords public_displays].freeze

  def social_shell?
    current_site.present? && SOCIAL_SHELL_EXCLUSIONS.exclude?(controller_path)
  end

  def social_nav_active?(destination)
    return true if destination == feed_path("main") && request.path == community_path

    request.path == destination || (destination != community_path && request.path.start_with?("#{destination}/"))
  end

  def person_initials(person)
    person&.display_name.to_s.split.filter_map { |part| part.first }.first(2).join.upcase.presence || "G"
  end

  def wedding_countdown(site)
    return "Date coming soon" unless site.wedding_date

    days = (site.wedding_date - Time.zone.today).to_i
    case days
    when 1.. then "#{pluralize(days, 'day')} to go"
    when 0 then "Today is the day"
    else "Married #{pluralize(days.abs, 'day')} ago"
    end
  end

  def social_icon(name)
    paths = {
      home: '<path d="M3 11.5 12 4l9 7.5v8a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
      announcement: '<path d="M4 13V9l12-5v14L4 13Zm0 0v5h4v-3.3M16 9h2.5a2.5 2.5 0 0 1 0 5H16"/>',
      people: '<circle cx="9" cy="8" r="3"/><path d="M3.5 20v-2a5.5 5.5 0 0 1 11 0v2M16 5.5a3 3 0 0 1 0 5.8M17 14a5 5 0 0 1 3.5 4.8V20"/>',
      calendar: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18M7 14h2M11 14h2M15 14h2M7 18h2M11 18h2"/>',
      image: '<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="8.5" cy="9" r="1.5"/><path d="m4 17 5-5 4 4 2-2 5 4"/>',
      groups: '<path d="M8 13a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm8-1a3.5 3.5 0 1 0 0-7M2 21v-2a6 6 0 0 1 12 0v2M15 15a5 5 0 0 1 7 4.6V21"/>',
      questions: '<path d="M21 12a8.5 8.5 0 0 1-9 8.5 10 10 0 0 1-4-.8L3 21l1.4-4A8.5 8.5 0 1 1 21 12Z"/><path d="M9.8 9a2.3 2.3 0 1 1 3 2.2c-.8.3-.8 1-.8 1.8M12 16h.01"/>',
      gift: '<rect x="3" y="9" width="18" height="12" rx="1"/><path d="M12 9v12M3 13h18M12 9H7.5a2.5 2.5 0 1 1 0-5C10.5 4 12 9 12 9Zm0 0h4.5a2.5 2.5 0 1 0 0-5C13.5 4 12 9 12 9Z"/>',
      chat: '<path d="M21 12a8.5 8.5 0 0 1-9 8.5 10 10 0 0 1-4-.8L3 21l1.4-4A8.5 8.5 0 1 1 21 12Z"/><path d="M8 12h.01M12 12h.01M16 12h.01"/>',
      inbox: '<path d="M4 4h16v16H4zM4 14h4l2 3h4l2-3h4"/>',
      settings: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1-2.8 2.8-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.6v.2h-4V21a1.7 1.7 0 0 0-1-1.6 1.7 1.7 0 0 0-1.9.3l-.1.1L4.2 17l.1-.1a1.7 1.7 0 0 0 .3-1.9A1.7 1.7 0 0 0 3 14H2.8v-4H3a1.7 1.7 0 0 0 1.6-1 1.7 1.7 0 0 0-.3-1.9L4.2 7 7 4.2l.1.1A1.7 1.7 0 0 0 9 4.6 1.7 1.7 0 0 0 10 3v-.2h4V3a1.7 1.7 0 0 0 1 1.6 1.7 1.7 0 0 0 1.9-.3l.1-.1L19.8 7l-.1.1a1.7 1.7 0 0 0-.3 1.9 1.7 1.7 0 0 0 1.6 1h.2v4H21a1.7 1.7 0 0 0-1.6 1Z"/>',
      menu: '<path d="M4 6h16M4 12h16M4 18h16"/>',
      plus: '<path d="M12 5v14M5 12h14"/>'
    }
    tag.svg(paths.fetch(name).html_safe, class: "social-icon", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.8, "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true)
  end
end
