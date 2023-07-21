# frozen_string_literal: true

module ScreenedEmailsExporter
  def screened_email_export
    return enum_for(:screened_email_export) unless block_given?

    ScreenedEmail
      .order("last_match_at DESC")
      .find_each { |screened_email| yield get_screened_email_fields(screened_email) }
  end

  def get_header(entity)
    if entity === "screened_email"
      %w[email action match_count last_match_at created_at ip_address]
    else
      super
    end
  end

  private

  def get_screened_email_fields(screened_email)
    screened_email_array = []

    get_header("screened_email").each do |attr|
      data =
        if attr == "action"
          ScreenedEmail.actions.key(screened_email.attributes["action_type"]).to_s
        else
          screened_email.attributes[attr]
        end

      screened_email_array.push(data)
    end

    screened_email_array
  end
end
