class PostBlockResponsesController < ApplicationController
  before_action :require_live_site!

  def update
    block = PostBlock.joins(:post).where(posts: { site_id: current_site.id }).find(params[:post_block_id])
    return redirect_to(fallback(block.post), alert: "That interaction is not available to you.") unless block.available_to?(Current.user) && block.interactive?

    response = block.responses.find_or_initialize_by(user: Current.user)
    return redirect_to(fallback(block.post), alert: "That response can no longer be changed.") unless block.response_editable?(response)

    selections = normalized_selections(block)
    saved = false
    block.with_lock do
      if block.signup? && block.capacity && selection_full?(block, response, selections.first)
        response.errors.add(:base, "That option is full")
      else
        saved = response.update(payload: { "selections" => selections }, submitted_at: Time.current)
      end
    end
    redirect_to fallback(block.post, anchor: helpers.dom_id(block)), **(saved ? { notice: "Response saved." } : { alert: response.errors.full_messages.to_sentence })
  end

  private

  def normalized_selections(block)
    selections = Array(params.dig(:post_block_response, :selections)).reject(&:blank?).map(&:to_s).uniq & block.options
    block.signup? ? selections.first(1) : selections
  end

  def selection_full?(block, response, selection)
    return false if selection.blank?

    count = block.responses.where.not(id: response.id).count { |entry| Array(entry.payload["selections"]).include?(selection) }
    count >= block.capacity
  end

  def fallback(post, anchor: nil)
    return group_path(post.group, anchor:) if post.group_space?

    feed_path(post.space, anchor:)
  end
end
