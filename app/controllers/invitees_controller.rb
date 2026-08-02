require "csv"

class InviteesController < ApplicationController
  before_action :require_site_manager!
  before_action :require_live_site!, except: :export

  def create
    invitee = current_site.invitees.build(invitee_params)
    if invitee.save
      redirect_to management_path, notice: "#{invitee.full_name} added to the guest list."
    else
      redirect_to management_path, alert: invitee.errors.full_messages.to_sentence
    end
  end

  def import
    upload = params[:file]
    return redirect_to(management_path, alert: "Choose a CSV file to import.") unless upload.respond_to?(:read)
    return redirect_to(management_path, alert: "The guest CSV must be 1 MB or smaller.") if upload.size > 1.megabyte

    rows = CSV.parse(upload.read, headers: true)
    return redirect_to(management_path, alert: "The guest CSV can contain at most 5,000 rows.") if rows.length > 5_000

    imported = import_rows!(rows)
    record_audit!("invitees.imported", metadata: { rows: imported })
    redirect_to management_path, notice: "Imported or updated #{imported} guest records."
  rescue CSV::MalformedCSVError, ActiveRecord::RecordInvalid => error
    redirect_to management_path, alert: "Guest import failed: #{error.message}"
  end

  def export
    data = CSV.generate(headers: true) do |csv|
      csv << [ "household", "first_name", "last_name", "email", "phone", "has_account" ]
      current_site.invitees.includes(:household, :user).order(:last_name, :first_name).each do |invitee|
        csv << [ invitee.household&.name, invitee.first_name, invitee.last_name, invitee.email, invitee.phone, invitee.user.present? ]
      end
    end
    send_data data, filename: "vowloom-guests.csv", type: "text/csv", disposition: "attachment"
  end

  private

  def require_site_manager!
    return if Current.user.owner? || Current.user.admin?

    redirect_to community_path, alert: "Only owners and admins can manage invitees."
  end

  def invitee_params
    params.require(:invitee).permit(:first_name, :last_name, :email, :phone, :household_id)
  end

  def import_rows!(rows)
    raise ActiveRecord::RecordInvalid.new(current_site.invitees.build), "CSV must include first_name and last_name columns" unless rows.headers&.include?("first_name") && rows.headers.include?("last_name")

    Site.transaction do
      rows.each_with_index do |row, index|
        first_name = row["first_name"].to_s.strip
        last_name = row["last_name"].to_s.strip
        raise ActiveRecord::RecordInvalid.new(current_site.invitees.build), "Row #{index + 2} needs a first and last name" if first_name.blank? || last_name.blank?

        household_name = row["household"].to_s.strip
        household = household_name.present? ? current_site.households.find_or_create_by!(name: household_name) : nil
        invitee = current_site.invitees.find_or_initialize_by(first_name:, last_name:, household:)
        invitee.assign_attributes(email: row["email"].to_s.strip.presence, phone: row["phone"].to_s.strip.presence)
        invitee.save!
      end
    end
    rows.length
  end
end
