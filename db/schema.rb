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

ActiveRecord::Schema.define(version: 20161001221350) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "actions", force: :cascade do |t|
    t.string   "kind"
    t.integer  "repo_id"
    t.string   "container_id"
    t.integer  "task_id"
    t.integer  "github_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "github_url"
    t.integer  "user_id"
    t.string   "title"
    t.text     "body"
    t.string   "github_status"
    t.string   "identifier"
    t.integer  "trigger_id"
  end

  add_index "actions", ["repo_id"], name: "index_actions_on_repo_id", using: :btree
  add_index "actions", ["task_id"], name: "index_actions_on_task_id", using: :btree

  create_table "behaviors", force: :cascade do |t|
    t.string  "kind"
    t.string  "name"
    t.string  "tone"
    t.string  "discovers"
    t.string  "image"
    t.text    "description"
    t.boolean "active"
    t.string  "triggers",        default: [], array: true
    t.string  "actions",         default: [], array: true
    t.string  "files",           default: [], array: true
    t.string  "tags",            default: [], array: true
    t.string  "repository_type"
    t.string  "repository_url"
    t.string  "author_name"
    t.string  "author_email"
    t.string  "icon_url"
    t.string  "checkout"
    t.string  "keywords",        default: [], array: true
    t.json    "settings"
  end

  add_index "behaviors", ["kind"], name: "index_behaviors_on_kind", unique: true, using: :btree

  create_table "discoveries", force: :cascade do |t|
    t.integer  "task_id"
    t.integer  "action_id"
    t.string   "identifier"
    t.boolean  "code_changed", default: false
    t.string   "priority"
    t.string   "title"
    t.text     "message"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "kind"
    t.string   "path"
    t.integer  "line"
    t.integer  "column"
    t.integer  "length"
    t.string   "branch"
  end

  add_index "discoveries", ["action_id"], name: "index_discoveries_on_action_id", using: :btree
  add_index "discoveries", ["identifier"], name: "index_discoveries_on_identifier", using: :btree
  add_index "discoveries", ["task_id"], name: "index_discoveries_on_task_id", using: :btree

  create_table "docker_events", force: :cascade do |t|
    t.integer  "repo_id"
    t.integer  "task_id"
    t.string   "event_id"
    t.string   "container_id"
    t.string   "status"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "docker_events", ["container_id"], name: "index_docker_events_on_container_id", using: :btree
  add_index "docker_events", ["repo_id"], name: "index_docker_events_on_repo_id", using: :btree
  add_index "docker_events", ["task_id"], name: "index_docker_events_on_task_id", using: :btree

  create_table "jobs", force: :cascade do |t|
    t.integer  "task_id"
    t.string   "slug"
    t.string   "status"
    t.text     "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "jobs", ["task_id"], name: "index_jobs_on_task_id", using: :btree

  create_table "memberships", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "repo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "memberships", ["user_id", "repo_id"], name: "index_memberships_on_user_id_and_repo_id", unique: true, using: :btree

  create_table "owners", force: :cascade do |t|
    t.integer "github_id"
    t.string  "name"
    t.boolean "organization"
  end

  add_index "owners", ["github_id"], name: "index_owners_on_github_id", unique: true, using: :btree

  create_table "repo_behaviors", force: :cascade do |t|
    t.integer "behavior_id"
    t.integer "repo_id"
  end

  add_index "repo_behaviors", ["repo_id", "behavior_id"], name: "index_repo_behaviors_on_repo_id_and_behavior_id", unique: true, using: :btree

  create_table "repos", force: :cascade do |t|
    t.integer  "github_id"
    t.string   "name"
    t.string   "owner"
    t.string   "github_full_name"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "owner_id"
    t.string   "webhook_id"
    t.boolean  "active",           default: false
    t.boolean  "private",          default: false
    t.string   "tags",             default: [],                 array: true
    t.string   "default_branch"
    t.text     "salt"
    t.text     "ssh_key"
    t.integer  "deploy_key_id"
    t.text     "webhook_token"
  end

  add_index "repos", ["github_full_name"], name: "index_repos_on_github_full_name", unique: true, using: :btree
  add_index "repos", ["github_id"], name: "index_repos_on_github_id", unique: true, using: :btree

  create_table "sequential", force: :cascade do |t|
    t.string   "model"
    t.string   "column"
    t.string   "scope"
    t.string   "scope_value"
    t.integer  "value"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "sequential", ["model", "column", "scope", "scope_value"], name: "index_sequential_on_model_and_column_and_scope_and_scope_value", unique: true, using: :btree

  create_table "settings", force: :cascade do |t|
    t.integer  "repo_behavior_id"
    t.string   "key"
    t.string   "value"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "settings", ["repo_behavior_id", "key"], name: "index_settings_on_repo_behavior_id_and_key", unique: true, using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "repo_id"
    t.string   "stripe_subscription_id"
    t.decimal  "price"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "subscriptions", ["repo_id"], name: "index_subscriptions_on_repo_id", using: :btree
  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id", using: :btree

  create_table "tasks", force: :cascade do |t|
    t.integer  "number",           default: 0
    t.integer  "repo_id"
    t.string   "container_id"
    t.integer  "duration",         default: 0
    t.string   "commit"
    t.string   "authors"
    t.string   "status",           default: "pending"
    t.string   "kind"
    t.datetime "completed_at"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.text     "logs"
    t.string   "container_status"
    t.integer  "trigger_id"
    t.string   "reason"
    t.integer  "behavior_id"
    t.integer  "sequential_id"
  end

  add_index "tasks", ["container_id"], name: "index_tasks_on_container_id", using: :btree
  add_index "tasks", ["repo_id"], name: "index_tasks_on_repo_id", using: :btree

  create_table "triggers", force: :cascade do |t|
    t.string   "kind"
    t.integer  "repo_id"
    t.integer  "triggered_by"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.json     "payload"
  end

  add_index "triggers", ["repo_id"], name: "index_triggers_on_repo_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.integer  "github_id"
    t.string   "email"
    t.string   "login"
    t.string   "name"
    t.string   "company"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.string   "gravatar_id"
    t.string   "avatar_url"
    t.string   "token"
    t.boolean  "syncing",              default: false
    t.datetime "last_synchronized_at"
    t.boolean  "beta",                 default: false
    t.string   "token_scopes"
    t.string   "stripe_customer_id"
    t.boolean  "onboarding_skipped",   default: false
  end

  add_index "users", ["github_id"], name: "index_users_on_github_id", using: :btree

end
