# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_04_24_235407) do
  create_table "continuous_glucose_levels", force: :cascade do |t|
    t.integer "member_id", null: false
    t.integer "value"
    t.datetime "tested_at"
    t.string "tz_offset"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_continuous_glucose_levels_on_member_id"
  end

  add_foreign_key "continuous_glucose_levels", "members"
end
