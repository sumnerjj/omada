require 'rails_helper'

RSpec.describe GlucoseStatsCalculator, type: :service do
  let(:member) { Member.create!(name: "Test User") }

  def create_reading(value, days_ago:)
    member.continuous_glucose_levels.create!(
      value: value,
      tested_at: Time.zone.now - days_ago.days,
      tz_offset: "-07:00"
    )
  end

  it "calculates all glucose metrics with change vs. prior period" do
    # Current period (last 7 days)
    create_reading(100, days_ago: 1)
    create_reading(190, days_ago: 2)  # above 180
    create_reading(60,  days_ago: 3)  # below 70

    # Prior period (8–14 days ago)
    create_reading(120, days_ago: 10)
    create_reading(70,  days_ago: 11)
    create_reading(200, days_ago: 12) # above 180

    now = Time.zone.now
    current_scope = member.continuous_glucose_levels.where(tested_at: now - 6.days..now.end_of_day)
    prior_scope   = member.continuous_glucose_levels.where(tested_at: now - 13.days..now - 7.days)

    result = GlucoseStatsCalculator.call(current_scope, prior_scope)

    # Manually compute expected values
    avg_current = ((100 + 190 + 60) / 3.0).round(1)
    avg_prior   = ((120 + 70 + 200) / 3.0).round(1)
    expected_avg_change = (avg_current - avg_prior).round(1)

    expect(result[:average]).to eq(avg_current)
    expect(result[:average_change]).to eq(expected_avg_change)

    expect(result[:time_above_range]).to eq((1 / 3.0 * 100).round(1))     # 1 of 3 above 180
    expect(result[:time_above_range_change]).to eq(((1 / 3.0 * 100) - (1 / 3.0 * 100)).round(1))

    expect(result[:time_below_range]).to eq((1 / 3.0 * 100).round(1))     # 1 of 3 below 70
    expect(result[:time_below_range_change]).to eq(((1 / 3.0 * 100) - (0 / 3.0 * 100)).round(1))
  end
end
