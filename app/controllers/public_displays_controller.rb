require "rqrcode"

class PublicDisplaysController < ApplicationController
  allow_unauthenticated_access

  def show
    @display = KioskDisplay.find_by!(access_token: params[:token], enabled: true)
    @site = @display.site
    @events = @site.events.site_wide.where("starts_at >= ?", Time.current).order(:starts_at).limit(5)
    @current_event = @site.events.site_wide.where("starts_at <= ?", Time.current).where("ends_at IS NULL OR ends_at >= ?", Time.current).order(starts_at: :desc).first
    @next_event = @events.first
    @media_assets = @site.media_assets.approved.where(featured: true).with_attached_file.order(created_at: :desc).limit(24)
    @announcements = @site.posts.visible.main.everyone.chronological.limit(4)
    @slideshow_asset = @media_assets[(Time.current.to_i / @display.refresh_seconds) % @media_assets.size] if @media_assets.any?
    if @display.questionnaire_results?
      candidate = @site.questionnaires.published.aggregate.includes(:group, :event, questions: :answers).find_by(id: @display.questionnaire_id)
      @questionnaire = candidate if candidate&.kiosk_displayable?
    end
    @questionnaire_results = aggregate_questionnaire_results if @questionnaire
    build_join_code if @display.show_qr_placeholder?
  end

  private

  def aggregate_questionnaire_results
    @questionnaire.questions.select { |question| kiosk_safe_question?(question) }.map do |question|
      selections = question.answers.flat_map do |answer|
        Array(answer.value.fetch("answer", nil)).map(&:to_s)
      end
      choices = question.yes_no? ? %w[yes no] : question.options.map(&:to_s)

      {
        question: question.prompt,
        response_count: question.answers.count,
        choices: choices.index_with { |choice| selections.count(choice) }
      }
    end
  end

  def kiosk_safe_question?(question)
    question.yes_no? || question.single_choice? || question.multiple_choice? || question.dropdown?
  end

  def build_join_code
    @join_url = root_url
    @join_qr_data_url = RQRCode::QRCode.new(@join_url, level: :m).as_png.resize(240, 240).to_data_url
  end
end
