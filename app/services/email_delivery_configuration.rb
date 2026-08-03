class EmailDeliveryConfiguration
  class << self
    def configured?
      ENV["VOWLOOM_SMTP_ADDRESS"].present?
    end

    def status
      configured? ? "Configured" : "Not configured"
    end

    def server_label
      return unless configured?

      "#{ENV.fetch('VOWLOOM_SMTP_ADDRESS')}:#{ENV.fetch('VOWLOOM_SMTP_PORT', 587)}"
    end
  end
end
