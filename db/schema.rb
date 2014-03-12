# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150428162204) do

  create_table "apps", force: true do |t|
    t.string   "name",                                       null: false
    t.string   "repo",                                       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "subscribe_to_github_webhook", default: true
    t.string   "github_webhook_secret"
    t.datetime "deleted_at"
    t.integer  "stack_id"
  end

  add_index "apps", ["deleted_at"], name: "index_apps_on_deleted_at", using: :btree
  add_index "apps", ["stack_id"], name: "index_apps_on_stack_id", using: :btree

  create_table "builds", force: true do |t|
    t.integer  "app_id",         null: false
    t.string   "ref",            null: false
    t.string   "callback_url"
    t.datetime "completed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "rref"
    t.text     "failure_reason"
    t.string   "state"
    t.string   "container_host"
    t.string   "container_id"
  end

  add_index "builds", ["app_id"], name: "index_builds_on_app_id", using: :btree

  create_table "config_sets", force: true do |t|
    t.text     "config",         limit: 2147483647, null: false
    t.integer  "app_id",                            null: false
    t.integer  "environment_id",                    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deploys", force: true do |t|
    t.integer  "build_id",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
    t.integer  "worker_id"
    t.integer  "environment_id", null: false
    t.integer  "app_id",         null: false
    t.string   "container_host"
    t.string   "container_id"
    t.datetime "completed_at"
    t.text     "failure_reason"
    t.string   "callback_url"
  end

  create_table "environments", force: true do |t|
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "environments", ["deleted_at"], name: "index_environments_on_deleted_at", using: :btree

  create_table "jockey_rds_database_instances", force: true do |t|
    t.string   "name",        null: false
    t.string   "environment", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reconciles", force: true do |t|
    t.integer  "environment_id"
    t.string   "state"
    t.string   "callback_url"
    t.text     "plan",           limit: 2147483647
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "completed_at"
    t.integer  "app_id"
    t.string   "container_id"
    t.string   "container_host"
    t.text     "failure_reason"
  end

  add_index "reconciles", ["app_id"], name: "index_reconciles_on_app_id", using: :btree
  add_index "reconciles", ["environment_id"], name: "index_reconciles_on_environment_id", using: :btree

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "stacks", force: true do |t|
    t.string "name"
  end

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "token"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "users", ["deleted_at"], name: "index_users_on_deleted_at", using: :btree

  create_table "versions", force: true do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "webhooks", force: true do |t|
    t.string   "url"
    t.string   "body"
    t.integer  "app_id"
    t.string   "type"
    t.boolean  "system"
    t.string   "room"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "webhooks", ["app_id"], name: "index_webhooks_on_app_id", using: :btree

  create_table "workers", force: true do |t|
    t.integer  "scale"
    t.string   "command"
    t.integer  "app_id"
    t.integer  "environment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  add_index "workers", ["app_id"], name: "index_workers_on_app_id", using: :btree
  add_index "workers", ["environment_id"], name: "index_workers_on_environment_id", using: :btree

end
