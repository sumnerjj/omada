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

csv_path = Rails.root.join('db/seeds/cgm_data_points_with_member_id.csv')

CSV.foreach(csv_path, headers: true) do |row|
  member = Member.find_or_create_by!(id: row["member_id"]) do |m|
    m.name = "Imported Member #{row['member_id']}"
  end

  ContinuousGlucoseLevel.create!(
    member: member,
    value: row["value"],
    tested_at: row["tested_at"],
    tz_offset: row["tz_offset"]
  )
end
