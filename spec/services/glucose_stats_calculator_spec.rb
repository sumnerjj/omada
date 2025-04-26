require 'rails_helper'

RSpec.describe GlucoseStatsCalculator, type: :service do
  let(:member) { Member.create!(name: "Stat Test Member") }

  def create_cgm(value:, days_ago:)
    member.continuous_glucose_levels.create!(
      value: value,
      tested_at: Time.zone.now - days_ago.days,
      tz_offset: "-07:00"
    )
  end

  describe "statistical calculations" do
    context "zero-data periods" do
      it "handles current and prior window both empty" do
        result = GlucoseStatsCalculator.call(ContinuousGlucoseLevel.none, ContinuousGlucoseLevel.none)

        expect(result[:average]).to be_nil
        expect(result[:time_above_range]).to eq(0.0)
        expect(result[:time_below_range]).to eq(0.0)
        expect(result[:average_change]).to be_nil
        expect(result[:time_above_range_change]).to eq(0.0)
        expect(result[:time_below_range_change]).to eq(0.0)
      end
    end

    context "single-reading periods" do
      it "handles exactly one reading" do
        create_cgm(value: 150, days_ago: 1) # In current window

        current_scope = member.continuous_glucose_levels.where(tested_at: Time.zone.now - 6.days..Time.zone.now)
        result = GlucoseStatsCalculator.call(current_scope, ContinuousGlucoseLevel.none)

        expect(result[:average]).to eq(150.0)
        expect(result[:time_above_range]).to eq(0.0) # 150 < 180
        expect(result[:time_below_range]).to eq(0.0) # 150 > 70
      end

      it "handles single reading above 180" do
        create_cgm(value: 190, days_ago: 1)

        current_scope = member.continuous_glucose_levels.where(tested_at: Time.zone.now - 6.days..Time.zone.now)
        result = GlucoseStatsCalculator.call(current_scope, ContinuousGlucoseLevel.none)

        expect(result[:time_above_range]).to eq(100.0)
        expect(result[:time_below_range]).to eq(0.0)
      end

      it "handles single reading below 70" do
        create_cgm(value: 65, days_ago: 1)

        current_scope = member.continuous_glucose_levels.where(tested_at: Time.zone.now - 6.days..Time.zone.now)
        result = GlucoseStatsCalculator.call(current_scope, ContinuousGlucoseLevel.none)

        expect(result[:time_below_range]).to eq(100.0)
        expect(result[:time_above_range]).to eq(0.0)
      end
    end

    context "boundary values" do
      it "does not count value == 180 as above" do
        create_cgm(value: 180, days_ago: 1)

        current_scope = member.continuous_glucose_levels.where(tested_at: Time.zone.now - 6.days..Time.zone.now)
        result = GlucoseStatsCalculator.call(current_scope, ContinuousGlucoseLevel.none)

        expect(result[:time_above_range]).to eq(0.0)
      end

      it "does not count value == 70 as below" do
        create_cgm(value: 70, days_ago: 1)

        current_scope = member.continuous_glucose_levels.where(tested_at: Time.zone.now - 6.days..Time.zone.now)
        result = GlucoseStatsCalculator.call(current_scope, ContinuousGlucoseLevel.none)

        expect(result[:time_below_range]).to eq(0.0)
      end
    end

    context "rounding behavior" do
      it "rounds correctly at .05 boundaries" do
        create_cgm(value: 180, days_ago: 1)
        create_cgm(value: 181, days_ago: 1)
        create_cgm(value: 181, days_ago: 1)
        create_cgm(value: 70,  days_ago: 1)
        create_cgm(value: 71,  days_ago: 1)

        current_scope = member.continuous_glucose_levels.where(tested_at: Time.zone.now - 6.days..Time.zone.now)
        result = GlucoseStatsCalculator.call(current_scope, ContinuousGlucoseLevel.none)

        expect(result[:average]).to be_within(0.05).of((180 + 181 + 181 + 70 + 71) / 5.0)
        expect(result[:time_above_range]).to eq((2 / 5.0 * 100).round(1))
        expect(result[:time_below_range]).to eq((0 / 5.0 * 100).round(1))
      end
    end

    context "change computations when only one period has data" do
      it "handles prior data but no current data" do
        create_cgm(value: 140, days_ago: 10) # prior window

        prior_scope = member.continuous_glucose_levels.where(tested_at: Time.zone.now - 13.days..Time.zone.now - 7.days)
        result = GlucoseStatsCalculator.call(ContinuousGlucoseLevel.none, prior_scope)

        expect(result[:average]).to be_nil
        expect(result[:average_change]).to be_nil
        expect(result[:time_above_range]).to eq(0.0)
        expect(result[:time_below_range]).to eq(0.0)
        expect(result[:time_above_range_change]).to eq((0.0 - 0.0).round(1))
      end

      it "handles current data but no prior data" do
        create_cgm(value: 160, days_ago: 1) # current window

        current_scope = member.continuous_glucose_levels.where(tested_at: Time.zone.now - 6.days..Time.zone.now)
        result = GlucoseStatsCalculator.call(current_scope, ContinuousGlucoseLevel.none)

        expect(result[:average]).to eq(160.0)
        expect(result[:average_change]).to be_nil
        expect(result[:time_above_range_change]).to eq(0.0)
        expect(result[:time_below_range_change]).to eq(0.0)
      end
    end
  end
end
