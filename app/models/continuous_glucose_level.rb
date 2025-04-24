class ContinuousGlucoseLevel < ApplicationRecord
  belongs_to :member

  validates :value, :tested_at, :tz_offset, presence: true
end
