class InvitationCode < ApplicationRecord
  belongs_to :site
  belongs_to :household, optional: true

  validates :code_digest, :code_fingerprint, presence: true
  validates :code_fingerprint, uniqueness: true

  def self.issue_for!(site:, household:, expires_at: nil)
    code = SecureRandom.alphanumeric(12).upcase
    create!(site:, household:, expires_at:, code_fingerprint: fingerprint_for(code), code_digest: BCrypt::Password.create(code))
    code
  end

  def self.find_active(site, code)
    return if code.blank?

    record = find_by(site:, code_fingerprint: fingerprint_for(code))
    record if record&.active_for?(code)
  end

  def self.fingerprint_for(code)
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, code.strip.upcase)
  end

  def active_for?(code)
    !expired? && BCrypt::Password.new(code_digest).is_password?(code.strip.upcase)
  end

  def expired?
    expires_at.present? && expires_at.past?
  end
end
