require "digest"

class ArchiveSnapshot < ApplicationRecord
  # Version 3 adds structured records for the planning surfaces that make a
  # wedding archive useful after the event.  The public payload is deliberately
  # useful without becoming an attendee directory or a copy of staff notes.
  MANIFEST_VERSION = 3

  belongs_to :site
  belongs_to :created_by, class_name: "User"

  validates :checksum, :frozen_at, presence: true

  def self.capture!(site:, actor:)
    captured_at = Time.current
    counts = content_counts_for(site)
    public_payload = build_payload(site, counts:, captured_at:)
    private_payload = build_payload(site, counts:, captured_at:, include_private: true)

    create!(
      site:,
      created_by: actor,
      manifest_version: MANIFEST_VERSION,
      content_counts: counts,
      public_payload:,
      private_payload:,
      checksum: checksum_for(public_payload:, private_payload:),
      frozen_at: captured_at
    )
  end

  def export_payload(include_private: false)
    payload = include_private ? private_payload : public_payload
    return payload.deep_symbolize_keys.merge(checksum:) if payload.present?

    # Snapshots made before payload persistence was introduced remain exportable.
    # Their data is reconstructed from the current site and should be re-frozen to
    # obtain an immutable preservation record.
    self.class.build_payload(site, counts: content_counts, captured_at: created_at, include_private:).merge(checksum:)
  end

  def self.build_payload(site, counts:, captured_at:, include_private: false)
    posts = published_posts_for(site, include_private:)
    media = site.media_assets.approved.with_attached_file.order(:created_at)
    media = media.where(post_id: posts.select(:id)).or(media.where(post_id: nil)) unless include_private
    events = include_private ? site.events : site.events.site_wide
    groups = include_private ? site.groups : site.groups.site_wide

    {
      format: "vowloom-portable-content-export",
      manifest_version: MANIFEST_VERSION,
      generated_at: captured_at.iso8601,
      frozen_at: captured_at.iso8601,
      site: { name: site.name, wedding_date: site.wedding_date, landing_message: site.landing_message, accent_color: site.accent_color },
      content_counts: counts,
      events: events.includes(event_invitations: { invitee: :household }).order(:starts_at).map { |event| event_payload(event, include_private:) },
      groups: groups.order(:name).map { |group| { name: group.name, description: group.description, visibility: group.visibility, participation: group.participation } },
      questionnaires: questionnaire_payloads(site, include_private:),
      registry: registry_payloads(site, include_private:),
      tasks: task_payloads(site, include_private:),
      privacy: privacy_notice(include_private),
      posts: posts.map { |post| { space: post.space, title: post.title, body: post.body, author: post.user.display_name, published_at: post.published_at, comments: post.comments.visible.map { |comment| { author: comment.user.display_name, body: comment.body, created_at: comment.created_at } } } },
      media: media.map(&:export_metadata)
    }
  end

  def self.content_counts_for(site)
    { posts: site.posts.count, comments: Comment.joins(:post).where(posts: { site_id: site.id }).count, events: site.events.count, groups: site.groups.count, media_assets: site.media_assets.count, approved_media_assets: site.media_assets.approved.count }
  end

  def self.checksum_for(public_payload:, private_payload:)
    Digest::SHA256.hexdigest(JSON.generate(manifest_version: MANIFEST_VERSION, public_payload:, private_payload:))
  end

  def self.published_posts_for(site, include_private:)
    posts = site.posts.visible.includes(:user, comments: :user).order(:published_at)
    return posts if include_private

    posts.where(visibility: :everyone)
         .where.not(space: :couple_inbox)
         .left_joins(:group)
         .where("posts.group_id IS NULL OR groups.visibility = ?", Group.visibilities.fetch("site_wide"))
  end

  def self.event_payload(event, include_private:)
    payload = {
      title: event.title,
      description: event.description,
      starts_at: event.starts_at,
      ends_at: event.ends_at,
      location_name: event.location_name,
      location_address: event.location_address,
      visibility: event.visibility,
      rsvp_totals: rsvp_totals(event.event_invitations)
    }
    return payload unless include_private

    payload.merge(
      meal_options: event.meal_options,
      rsvps: event.event_invitations.sort_by { |invitation| invitation.invitee.full_name }.map do |invitation|
        {
          invitee: invitation.invitee.full_name,
          household: invitation.invitee.household&.name,
          status: invitation.rsvp_status,
          meal_choice: invitation.meal_choice,
          dietary_notes: invitation.dietary_notes,
          accessibility_notes: invitation.accessibility_notes,
          responded_at: invitation.responded_at
        }
      end
    )
  end

  def self.rsvp_totals(invitations)
    EventInvitation.rsvp_statuses.keys.index_with { |status| invitations.count { |invitation| invitation.rsvp_status == status } }
  end

  def self.questionnaire_payloads(site, include_private:)
    questionnaires = site.questionnaires.includes(questions: { answers: [ :questionnaire_response, { file_attachment: :blob } ] }, responses: [ :user, :invitee, :household, { answers: [ :question, { file_attachment: :blob } ] } ]).order(:created_at)
    questionnaires = questionnaires.reject { |questionnaire| !public_questionnaire?(questionnaire) } unless include_private

    questionnaires.map do |questionnaire|
      payload = {
        title: questionnaire.title,
        introduction: questionnaire.introduction,
        status: questionnaire.status,
        response_scope: questionnaire.response_scope,
        results_visibility: questionnaire.results_visibility,
        opens_at: questionnaire.opens_at,
        closes_at: questionnaire.closes_at,
        questions: questionnaire.questions.map { |question| question_payload(question, include_private:) }
      }
      include_private ? payload.merge(responses: private_questionnaire_responses(questionnaire)) : payload
    end
  end

  def self.public_questionnaire?(questionnaire)
    !questionnaire.draft? && questionnaire.group_id.nil? && (questionnaire.event.nil? || questionnaire.event.site_wide?) && questionnaire.results_visibility.in?(%w[aggregate member_visible])
  end

  def self.question_payload(question, include_private:)
    payload = {
      prompt: question.prompt,
      kind: question.kind,
      required: question.required,
      options: question.options,
      conditional_rule: question.conditional_rule
    }
    return payload if include_private

    payload.merge(aggregate: aggregate_question_answers(question))
  end

  def self.aggregate_question_answers(question)
    answers = question.answers.select { |answer| answer.questionnaire_response.submitted_at.present? }
    values = answers.filter_map { |answer| answer.value["answer"] }
    aggregate = { submitted_response_count: question.questionnaire.responses.where.not(submitted_at: nil).count, answered_count: answers.count }

    case question.kind
    when "yes_no", "single_choice", "multiple_choice", "dropdown", "rating"
      aggregate[:choice_counts] = values.flat_map { |value| Array(value) }.compact.tally
    when "number"
      numbers = values.filter_map { |value| Float(value) rescue nil }
      aggregate[:numeric_summary] = { count: numbers.count, minimum: numbers.min, maximum: numbers.max, average: numbers.sum.fdiv(numbers.count).round(2) } if numbers.any?
    end
    aggregate
  end

  def self.private_questionnaire_responses(questionnaire)
    questionnaire.responses.select { |response| response.submitted_at.present? }.map do |response|
      {
        respondent: response.user&.display_name || response.invitee&.full_name || response.household&.name || "Unknown",
        respondent_type: response.user_id.present? ? "member" : response.invitee_id.present? ? "invitee" : "household",
        submitted_at: response.submitted_at,
        answers: response.answers.map do |answer|
          {
            prompt: answer.question.prompt,
            kind: answer.question.kind,
            value: answer.question.file? ? nil : answer.value["answer"],
            file: attachment_metadata(answer.file)
          }
        end
      }
    end
  end

  def self.registry_payloads(site, include_private:)
    collections = site.registry_collections.includes(registry_items: [ { registry_claims: :user }, { image_attachment: :blob } ]).order(:created_at)
    collections = collections.where(published: true, visibility: :everyone) unless include_private

    collections.map do |collection|
      {
        title: collection.title,
        description: collection.description,
        visibility: collection.visibility,
        published: collection.published,
        items: collection.registry_items.select { |item| include_private || item.published? }.map { |item| registry_item_payload(item, include_private:) }
      }
    end
  end

  def self.registry_item_payload(item, include_private:)
    payload = {
      title: item.title,
      description: item.description,
      category: item.category,
      external_url: item.external_url,
      price_cents: item.price_cents,
      currency: item.currency,
      priority: item.priority,
      quantity_requested: item.quantity_requested,
      available_quantity: item.available_quantity,
      published: item.published,
      claim_totals: item.registry_claims.group_by(&:status).transform_values(&:count),
      image: attachment_metadata(item.image)
    }
    return payload unless include_private

    payload.merge(
      claims: item.registry_claims.map do |claim|
        {
          purchaser: claim.user.display_name,
          quantity: claim.quantity,
          status: claim.status,
          private_note: claim.private_note,
          purchased_at: claim.purchased_at,
          received_at: claim.received_at,
          purchaser_revealed_at: claim.purchaser_revealed_at,
          thank_you_sent_at: claim.thank_you_sent_at
        }
      end
    )
  end

  def self.task_payloads(site, include_private:)
    return [] unless include_private

    site.groups.includes(tasks: [ :assigned_user, :event, { task_comments: :user } ]).order(:name).flat_map do |group|
      group.tasks.map do |task|
        {
          group: group.name,
          title: task.title,
          description: task.description,
          assigned_to: task.assigned_user&.display_name,
          event: task.event&.title,
          due_on: task.due_on,
          completed_at: task.completed_at,
          comments: task.task_comments.map { |comment| { author: comment.user.display_name, body: comment.body, created_at: comment.created_at } }
        }
      end
    end
  end

  def self.attachment_metadata(attachment)
    return unless attachment.attached?

    { filename: attachment.filename.to_s, content_type: attachment.content_type, byte_size: attachment.byte_size, checksum: attachment.blob.checksum }
  end

  def self.privacy_notice(include_private)
    return "excludes member-only posts, Couple Inbox conversations, RSVP identities and notes, individual questionnaire answers, registry claimants, planning tasks, contact details, credentials, and invitation codes" unless include_private

    "includes private posts, private groups, detailed RSVP and questionnaire records, registry claims, and planning tasks for the Owner; excludes passwords, sessions, recovery details, invitation codes, and contact details"
  end
end
