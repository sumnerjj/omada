class Member < ApplicationRecord
    has_many :continuous_glucose_levels, dependent: :destroy
  end
  