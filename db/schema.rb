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

ActiveRecord::Schema[8.0].define(version: 2025_08_09_223338) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "adult_roles", force: :cascade do |t|
    t.bigint "adult_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["adult_id", "role_id"], name: "index_adult_roles_on_adult_id_and_role_id", unique: true
    t.index ["adult_id"], name: "index_adult_roles_on_adult_id"
    t.index ["role_id"], name: "index_adult_roles_on_role_id"
  end

  create_table "adults", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.bigint "family_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.index ["email"], name: "index_adults_on_email", unique: true
    t.index ["family_id"], name: "index_adults_on_family_id"
    t.index ["reset_password_token"], name: "index_adults_on_reset_password_token", unique: true
  end

  create_table "child_roles", force: :cascade do |t|
    t.bigint "child_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id", "role_id"], name: "index_child_roles_on_child_id_and_role_id", unique: true
    t.index ["child_id"], name: "index_child_roles_on_child_id"
    t.index ["role_id"], name: "index_child_roles_on_role_id"
  end

  create_table "children", force: :cascade do |t|
    t.string "first_name"
    t.date "birth_date"
    t.string "avatar_color"
    t.boolean "active"
    t.bigint "family_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_children_on_family_id"
  end

  create_table "chore_assignments", force: :cascade do |t|
    t.bigint "chore_id", null: false
    t.bigint "child_id", null: false
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id"], name: "index_chore_assignments_on_child_id"
    t.index ["chore_id"], name: "index_chore_assignments_on_chore_id"
  end

  create_table "chore_completions", force: :cascade do |t|
    t.bigint "chore_list_id", null: false
    t.bigint "chore_id", null: false
    t.bigint "child_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "completed_at"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.text "review_notes"
    t.decimal "earned_amount", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id", "created_at"], name: "index_chore_completions_on_child_id_and_created_at"
    t.index ["child_id"], name: "index_chore_completions_on_child_id"
    t.index ["chore_id"], name: "index_chore_completions_on_chore_id"
    t.index ["chore_list_id"], name: "index_chore_completions_on_chore_list_id"
    t.index ["completed_at"], name: "index_chore_completions_on_completed_at"
    t.index ["reviewed_by_id"], name: "index_chore_completions_on_reviewed_by_id"
    t.index ["status"], name: "index_chore_completions_on_status"
  end

  create_table "chore_lists", force: :cascade do |t|
    t.bigint "child_id", null: false
    t.integer "interval", default: 0, null: false
    t.date "start_date", null: false
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id", "start_date", "interval"], name: "index_unique_chore_list_per_child_date_interval", unique: true
    t.index ["child_id"], name: "index_chore_lists_on_child_id"
    t.index ["start_date"], name: "index_chore_lists_on_start_date"
  end

  create_table "chores", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.text "instructions"
    t.integer "chore_type"
    t.integer "difficulty"
    t.integer "estimated_minutes"
    t.integer "min_age"
    t.integer "max_age"
    t.decimal "base_value"
    t.boolean "active"
    t.bigint "family_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_chores_on_family_id"
  end

  create_table "daily_chore_lists", force: :cascade do |t|
    t.bigint "child_id", null: false
    t.date "date"
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id"], name: "index_daily_chore_lists_on_child_id"
  end

  create_table "extra_completions", force: :cascade do |t|
    t.bigint "child_id", null: false
    t.bigint "extra_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "completed_at"
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.decimal "earned_amount", precision: 8, scale: 2, default: "0.0"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_at"], name: "index_extra_completions_on_approved_at"
    t.index ["approved_by_id"], name: "index_extra_completions_on_approved_by_id"
    t.index ["child_id", "status"], name: "index_extra_completions_on_child_id_and_status"
    t.index ["child_id"], name: "index_extra_completions_on_child_id"
    t.index ["completed_at"], name: "index_extra_completions_on_completed_at"
    t.index ["extra_id"], name: "index_extra_completions_on_extra_id"
  end

  create_table "extras", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.decimal "reward_amount"
    t.date "available_from"
    t.date "available_until"
    t.integer "max_completions"
    t.boolean "active"
    t.bigint "family_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_extras_on_family_id"
  end

  create_table "families", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_families_on_name"
  end

  create_table "family_settings", force: :cascade do |t|
    t.bigint "family_id", null: false
    t.integer "payout_interval_days"
    t.decimal "base_chore_value"
    t.integer "auto_approve_after_hours"
    t.text "notification_settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_family_settings_on_family_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  add_foreign_key "adult_roles", "adults"
  add_foreign_key "adult_roles", "roles"
  add_foreign_key "child_roles", "children"
  add_foreign_key "child_roles", "roles"
  add_foreign_key "children", "families"
  add_foreign_key "chore_assignments", "children"
  add_foreign_key "chore_assignments", "chores"
  add_foreign_key "chore_completions", "adults", column: "reviewed_by_id"
  add_foreign_key "chore_completions", "children"
  add_foreign_key "chore_completions", "chore_lists"
  add_foreign_key "chore_completions", "chores"
  add_foreign_key "chore_lists", "children"
  add_foreign_key "chores", "families"
  add_foreign_key "daily_chore_lists", "children"
  add_foreign_key "extra_completions", "adults", column: "approved_by_id"
  add_foreign_key "extra_completions", "children"
  add_foreign_key "extra_completions", "extras"
  add_foreign_key "extras", "families"
  add_foreign_key "family_settings", "families"
end
