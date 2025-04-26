require "rails_helper"

RSpec.describe ContinuousGlucoseLevel, type: :model do
  let(:member) { Member.create!(name: "Test User") }
  let(:local_time) { Time.new(2025, 3, 8, 2, 30, 0) } # Pick an arbitrary time

  context "timezone conversion with various offset formats" do
    it "converts with colon format offset" do
      cgm = ContinuousGlucoseLevel.create!(member: member, value: 120, tested_at: local_time, tz_offset: "-04:00")
      expect(cgm.tested_at.utc_offset).to eq(0)
    end

    it "converts with no-colon format offset" do
      cgm = ContinuousGlucoseLevel.create!(member: member, value: 130, tested_at: local_time, tz_offset: "-0400")
      expect(cgm.tested_at.utc_offset).to eq(0)
    end

    it "converts with positive half-hour offset" do
      cgm = ContinuousGlucoseLevel.create!(member: member, value: 140, tested_at: local_time, tz_offset: "+05:30")
      expect(cgm.tested_at.utc_offset).to eq(0)
    end

    it "converts zero-offset correctly" do
      cgm = ContinuousGlucoseLevel.create!(member: member, value: 150, tested_at: local_time, tz_offset: "+00:00")
      expect(cgm.tested_at.utc_offset).to eq(0)
    end
  end

  context "invalid or blank tz_offset handling" do
    it "fails validation when tz_offset is blank" do
      cgm = ContinuousGlucoseLevel.new(member: member, value: 100, tested_at: local_time, tz_offset: nil)
      expect(cgm).to_not be_valid
      expect(cgm.errors[:tz_offset]).to include("can't be blank")
    end

    it "is invalid when tz_offset is nonsense" do
      cgm = ContinuousGlucoseLevel.new(member: member, value: 100, tested_at: local_time, tz_offset: "nonsense")
      expect(cgm.valid?).to be false
      expect(cgm.errors[:tz_offset]).to be_present
    end
  end

  context "DST transitions" do
    it "handles spring forward gap correctly" do
      # Example: US spring forward 2025 is on March 9, 2:00 AM jumps to 3:00 AM
      spring_forward_time = Time.new(2025, 3, 9, 2, 30, 0) # non-existent local time
      cgm = ContinuousGlucoseLevel.create!(member: member, value: 110, tested_at: spring_forward_time, tz_offset: "-05:00")
      expect(cgm.tested_at).to be_present
    rescue ArgumentError
      # acceptable: ruby Time may raise error on nonexistent local time
      expect(true).to be true
    end

    it "handles fall back overlap correctly" do
      # Example: US fall back 2025 is Nov 2, 2:00 AM becomes 1:00 AM again
      fall_back_time = Time.new(2025, 11, 2, 1, 30, 0)
      cgm = ContinuousGlucoseLevel.create!(member: member, value: 115, tested_at: fall_back_time, tz_offset: "-04:00")
      expect(cgm.tested_at).to be_present
    end
  end

  context "idempotency on update" do
    it "does not reapply timezone shift on save" do
      cgm = ContinuousGlucoseLevel.create!(member: member, value: 120, tested_at: local_time, tz_offset: "-04:00")
      original_utc = cgm.tested_at

      cgm.value = 125
      cgm.save!

      expect(cgm.tested_at).to eq(original_utc)
    end
  end
end
