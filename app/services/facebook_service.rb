# frozen_string_literal: true

class FacebookService
  def initialize(user)
    @user = user
  end

  def provider
    @provider ||= @user.providers.find_by(name: "facebook")
  end

  def client
    @client ||= Koala::Facebook::API.new(provider.token)
  end

  def uids
    client.get_connections(:me, :friends).map { |friend| friend["id"] }
  end

  def share!(checkin)
    if checkin.facebook_url_hash.blank?
      checkin.update_column(:facebook_url_hash, checkin.generate_url_hash)
    end

    title = checkin.work.title
    episode_title = checkin.episode.decorate.title_with_number
    title += " #{episode_title}" if title != episode_title
    message = checkin.comment.squish if checkin.comment.present?
    link = if Rails.env.development?
      "https://annict.com/r/fb/#{checkin.facebook_url_hash}"
    else
      "#{checkin.user.annict_url}/r/fb/#{checkin.facebook_url_hash}"
    end
    caption = "Annict | アニクト - 見たアニメを記録して、共有しよう"

    work_image = checkin.work.work_image
    source = if work_image.present? && Rails.env.production?
      # Using `rescue` to avoid occurring error `undefined method `ann_image_url'`
      work_image.decorate.image_url(:attachment, size: "600x315") rescue nil # rubocop:disable Style/RescueModifier
    end
    source = "https://annict.com/images/og_image.png" if source.blank?

    client.put_connections("me", "feed",
      name: title,
      message: message,
      link: link,
      caption: caption,
      source: source)
  end

  def share_review!(review, image_url)
    client.put_connections("me", "feed",
      name: review.work.title,
      message: review.body,
      link: review.decorate.detail_url,
      caption: "Annict | アニクト - 見たアニメを記録して、共有しよう",
      source: image_url)
  end
end
