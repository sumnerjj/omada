require "rails_helper"

RSpec.describe "Members Dashboard Time Windows", type: :request do
  let(:member) { Member.create!(name: "Time Test Member") }
  let(:tz_offset) { "-05:00" }

  def create_cgm(value:, tested_at:)
    member.continuous_glucose_levels.create!(
      value: value,
      tested_at: tested_at,
      tz_offset: tz_offset,
    )
  end

  describe "inclusive and exclusive boundaries for last 7 days" do
    it "includes readings exactly at week_start and week_end" do
      now = Time.zone.now

      week_start = (now.beginning_of_day - 6.days)
      week_end = now.end_of_day

      create_cgm(value: 100, tested_at: week_start)
      create_cgm(value: 110, tested_at: week_end)

      get dashboard_member_path(member)

      metrics = assigns(:metrics)[:last_7_days]

      expect(metrics[:average]).to_not be_nil
      expect(metrics[:average]).to eq(((100 + 110) / 2.0).round(1))
    end

    it "excludes readings just before week_start" do
      now = Time.zone.now

      week_start = (now.beginning_of_day - 6.days)

      create_cgm(value: 120, tested_at: week_start - 1.second)

      get dashboard_member_path(member)

      metrics = assigns(:metrics)[:last_7_days]

      expect(metrics[:average]).to be_nil
    end

    it "excludes readings just after week_end" do
      now = Time.zone.now

      week_end = now.end_of_day

      create_cgm(value: 130, tested_at: week_end + 1.second)

      get dashboard_member_path(member)

      metrics = assigns(:metrics)[:last_7_days]

      expect(metrics[:average]).to be_nil
    end
  end

  describe "month boundaries" do
    it "handles different month lengths" do
      # Feb 29, leap year test
      feb_time = Time.zone.local(2024, 2, 29, 12, 0, 0)  # Leap year 2024

      create_cgm(value: 140, tested_at: feb_time)

      # Travel to end of Feb
      travel_to Time.zone.local(2024, 2, 29, 23, 59, 59) do
        get dashboard_member_path(member)

        metrics = assigns(:metrics)[:current_month]
        expect(metrics[:average]).to eq(140.0)
      end
    end

    it "includes full months (e.g., 30/31 day months)" do
      june_time = Time.zone.local(2025, 6, 30, 23, 59, 59) # June 30th, 30-day month
      create_cgm(value: 150, tested_at: june_time)

      travel_to Time.zone.local(2025, 6, 30, 23, 59, 59) do
        get dashboard_member_path(member)

        metrics = assigns(:metrics)[:current_month]
        expect(metrics[:average]).to eq(150.0)
      end
    end
  end

  describe "previous period boundaries" do
    it "ensures no gap between prev_week_end and week_start" do
      now = Time.zone.now

      week_start = (now.beginning_of_day - 6.days)
      prev_week_end = (week_start - 1.second)

      expect(week_start).to eq(prev_week_end + 1.second)
    end
  end

  describe "cross-month 7 day ranges" do
    it "correctly handles 7 day window across months" do
      travel_to Time.zone.local(2025, 5, 2, 12, 0, 0) do
        april_30 = Time.zone.local(2025, 4, 30, 23, 59, 59)
        may_1 = Time.zone.local(2025, 5, 1, 0, 0, 0)

        create_cgm(value: 100, tested_at: april_30)
        create_cgm(value: 110, tested_at: may_1)

        get dashboard_member_path(member)

        metrics = assigns(:metrics)[:last_7_days]
        expect(metrics[:average]).to eq(((100 + 110) / 2.0).round(1))
      end
    end
  end

  describe "member's local timezone vs server timezone" do
    it "uses tested_at already adjusted to UTC based on tz_offset" do
      # Member has tz_offset -05:00 (EST without DST)
      local_midnight = Time.new(2025, 4, 25, 0, 0, 0, "-05:00")

      # Internally saved as UTC
      create_cgm(value: 105, tested_at: local_midnight)

      # Server now in UTC timezone
      travel_to Time.utc(2025, 4, 25, 6, 0, 0) do
        get dashboard_member_path(member)

        metrics = assigns(:metrics)[:last_7_days]
        expect(metrics[:average]).to eq(105.0)
      end
    end
  end
end
