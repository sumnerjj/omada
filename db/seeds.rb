# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


require 'csv'
require 'time'

CSV.foreach(Rails.root.join("db/seeds/cgm_data_points_with_member_id.csv"), headers: true).with_index do |row, i|
#   puts "Row ##{i + 1}: #{row.to_h}"

  member = Member.find_or_create_by!(id: row["member_id"].to_i) do |m|
    m.name = "Imported Member #{row['member_id']}"
  end

  tested_at = Time.strptime(row["tested_at"].strip, "%m/%d/%y %H:%M")
  tz_offset = row["tz_offset"].tr("“”", '"').strip

  ContinuousGlucoseLevel.create!(
    member: member,
    value: row["value"].to_i,
    tested_at: tested_at,
    tz_offset: tz_offset
  )
end
