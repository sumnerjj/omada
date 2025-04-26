class ContinuousGlucoseLevel < ApplicationRecord
  belongs_to :member

  VALID_TZ_OFFSET_REGEX = /\A[+-](0[0-9]|1[0-2]):?[0-5][0-9]\z/

  validates :value, :tested_at, :tz_offset, presence: true
  validates :tz_offset, format: { with: VALID_TZ_OFFSET_REGEX, message: "must be in format ±HH:MM or ±HHMM" }

  before_validation :adjust_tested_at_to_utc, on: [:create, :update]

  private

  def adjust_tested_at_to_utc
    return if tested_at.blank? || tz_offset.blank?
    return if tested_at.utc?

    local_time_string = tested_at.strftime("%Y-%m-%d %H:%M:%S")
    time_with_offset = Time.strptime("#{local_time_string} #{tz_offset}", "%Y-%m-%d %H:%M:%S %z")
    self.tested_at = time_with_offset.utc
  end
end
