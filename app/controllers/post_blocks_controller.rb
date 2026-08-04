class PostBlocksController < ApplicationController
  before_action :require_live_site!

  def create
    post = current_site.posts.find(params[:post_id])
    return redirect_to(fallback(post), alert: "You cannot add controls to that post.") unless post.manageable_by?(Current.user)

    block = post.post_blocks.build(block_attributes.merge(created_by: Current.user, position: post.post_blocks.maximum(:position).to_i + 1))
    assign_resource(block)
    block.files.attach(Array(params.dig(:post_block, :files)).reject(&:blank?))
    if block.save
      block.materialize_media!(site: current_site, user: Current.user)
      redirect_to fallback(post, anchor: helpers.dom_id(post)), notice: "Interactive block added."
    else
      redirect_to fallback(post, anchor: helpers.dom_id(post)), alert: block.errors.full_messages.to_sentence
    end
  end

  def destroy
    block = PostBlock.joins(:post).where(posts: { site_id: current_site.id }).find(params[:id])
    post = block.post
    return redirect_to(fallback(post), alert: "You cannot remove that block.") unless post.manageable_by?(Current.user)

    block.destroy!
    redirect_to fallback(post, anchor: helpers.dom_id(post)), notice: "Block removed."
  end

  def update
    block = PostBlock.joins(:post).where(posts: { site_id: current_site.id }).find(params[:id])
    return redirect_to(fallback(block.post), alert: "This element is display-only.") unless block.contributable_by?(Current.user)

    update_sticky_note!(block)
    redirect_to fallback(block.post, anchor: helpers.dom_id(block)), notice: "#{block.kind.humanize} updated."
  rescue ActiveRecord::StaleObjectError
    redirect_to fallback(block.post, anchor: helpers.dom_id(block)), alert: "Someone else updated this element first. Reload and apply your change again."
  rescue JSON::ParserError, ActionController::BadRequest
    redirect_to fallback(block.post, anchor: helpers.dom_id(block)), alert: "That element update was not valid."
  end

  private

  def block_attributes
    input = params.require(:post_block).permit(:kind, :title, :body, :opens_at, :closes_at, :options_text, :audience, :results_visibility, :response_edit_policy, :capacity, :address, :map_url, :interactive, :resource_key, files: [])
    input.delete(:files)
    options = input.delete(:options_text).to_s.lines.map(&:strip).reject(&:blank?)
    settings = {
      "options" => options,
      "items" => options.map { |text| { "id" => SecureRandom.hex(6), "text" => text, "done" => false } },
      "grid" => Array.new(4) { Array.new(3, "") },
      "interactive" => ActiveModel::Type::Boolean.new.cast(input.delete(:interactive)),
      "audience" => input.delete(:audience).presence_in(%w[members staff]) || "members",
      "results_visibility" => input.delete(:results_visibility).presence_in(%w[participants members staff]) || "participants",
      "response_edit_policy" => input.delete(:response_edit_policy).presence_in(%w[editable locked]) || "editable",
      "capacity" => input.delete(:capacity).to_i,
      "address" => input.delete(:address).to_s,
      "map_url" => input.delete(:map_url).to_s
    }
    input.except(:resource_key).merge(settings:)
  end

  def update_sticky_note!(block)
    attributes = params.require(:post_block).permit(:body, :lock_version, :grid_json, :items_json)
    block.lock_version = attributes[:lock_version] if attributes[:lock_version].present?
    if block.note?
      block.update!(body: attributes[:body].to_s.first(10_000))
    elsif block.sheet?
      block.update!(settings: block.settings.merge("grid" => normalized_grid(attributes.fetch(:grid_json))))
    elsif block.list?
      block.update!(settings: block.settings.merge("items" => normalized_items(attributes.fetch(:items_json))))
    else
      raise ActionController::BadRequest
    end
  end

  def normalized_grid(json)
    grid = JSON.parse(json).first(30).map { |row| Array(row).first(12).map { |cell| cell.to_s.first(500) } }
    raise ActionController::BadRequest unless grid.any?

    grid
  end

  def normalized_items(json)
    JSON.parse(json).first(100).filter_map do |item|
      text = item["text"].to_s.strip.first(500)
      next if text.blank?

      identifier = item["id"].to_s.gsub(/[^a-zA-Z0-9-]/, "").first(50).presence || SecureRandom.hex(6)
      { "id" => identifier, "text" => text, "done" => ActiveModel::Type::Boolean.new.cast(item["done"]), "updated_by" => Current.user.display_name, "updated_at" => Time.current.iso8601 }
    end
  end

  def assign_resource(block)
    resource_key = params.dig(:post_block, :resource_key).to_s
    return if resource_key.blank?

    type, id = resource_key.split(":", 2)
    block.blockable = case type
    when "Questionnaire" then current_site.questionnaires.find(id)
    when "Event" then current_site.events.find(id)
    when "Album" then current_site.albums.find(id)
    end
  end

  def fallback(post, anchor: nil)
    return group_path(post.group, anchor:) if post.group_space?

    feed_path(post.space, anchor:)
  end
end
