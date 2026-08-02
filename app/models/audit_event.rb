class AuditEvent < ApplicationRecord
  belongs_to :site
  belongs_to :actor, class_name: "User"
  belongs_to :auditable, polymorphic: true, optional: true

  validates :action, presence: true, length: { maximum: 120 }
end
