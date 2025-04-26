require 'csv'
require 'time'

puts "Resetting database..."

# Delete existing records
ContinuousGlucoseLevel.delete_all
Member.delete_all

# Reset SQLite autoincrement counters
ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='continuous_glucose_levels';")
ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='members';")

puts "Database cleared."

record_count = 0

CSV.foreach(Rails.root.join("db/seeds/cgm_data_points_3_members.csv"), headers: true).with_index do |row, i|
  member = Member.find_or_create_by!(id: row["member_id"].to_i) do |m|
    m.name = "Imported Member #{row['member_id']}"
  end

  begin
    # Parse local tested_at
    local_tested_at = Time.strptime(row["tested_at"].strip, "%m/%d/%y %H:%M")

    # Clean tz_offset: remove any curly quotes, straight quotes, single quotes
    tz_offset = row["tz_offset"].gsub(/[“”"']/, '').strip

    # Combine local tested_at with tz_offset properly
    tested_at_with_offset = Time.strptime("#{local_tested_at.strftime("%Y-%m-%d %H:%M:%S")} #{tz_offset}", "%Y-%m-%d %H:%M:%S %z")

    ContinuousGlucoseLevel.create!(
      member: member,
      value: row["value"].to_i,
      tested_at: tested_at_with_offset.utc,  # Store real UTC time
      tz_offset: tz_offset
    )

    record_count = i + 1

  rescue ArgumentError => e
    puts "⚠️ Skipping bad row ##{i + 1}: #{e.message}"
  end
end

puts "✅ Successfully processed #{record_count} records"
