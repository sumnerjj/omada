class ContinuousGlucoseLevel < ApplicationRecord
  belongs_to :member

  validates :value, :tested_at, :tz_offset, presence: true

  before_validation :adjust_tested_at_to_utc, on: [:create, :update]

  private

  def adjust_tested_at_to_utc
    return if tested_at.blank? || tz_offset.blank?

    # Format tested_at as a naive string
    local_time_string = tested_at.strftime("%Y-%m-%d %H:%M:%S")

    # Apply tz_offset manually to interpret it as the correct UTC
    time_with_offset = Time.strptime("#{local_time_string} #{tz_offset}", "%Y-%m-%d %H:%M:%S %z")

    # Save true UTC time into tested_at
    self.tested_at = time_with_offset.utc
  end
end
