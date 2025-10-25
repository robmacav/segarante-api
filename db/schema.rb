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

ActiveRecord::Schema[8.0].define(version: 2025_10_22_175649) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "apolices", force: :cascade do |t|
    t.bigint "numero", null: false
    t.date "data_emissao", null: false
    t.date "inicio_vigencia", null: false
    t.date "fim_vigencia", null: false
    t.decimal "importancia_segurada", precision: 15, scale: 2, null: false
    t.decimal "lmg", precision: 15, scale: 2, null: false
    t.date "fim_vigencia_original", null: false
    t.decimal "importancia_segurada_original", precision: 15, scale: 2, null: false
    t.decimal "lmg_original", precision: 15, scale: 2, null: false
    t.integer "status", null: false
    t.index ["numero"], name: "index_apolices_on_numero", unique: true
  end

  create_table "endossos", force: :cascade do |t|
    t.date "data_emissao", null: false
    t.date "fim_vigencia"
    t.decimal "importancia_segurada", precision: 15, scale: 2
    t.bigint "endosso_cancelador_id"
    t.bigint "endosso_cancelamento_id"
    t.integer "tipo", default: 0, null: false
    t.bigint "apolice_numero", null: false
    t.index ["apolice_numero"], name: "index_endossos_on_apolice_numero"
    t.index ["endosso_cancelador_id"], name: "index_endossos_on_endosso_cancelador_id"
    t.index ["endosso_cancelamento_id"], name: "index_endossos_on_endosso_cancelamento_id"
  end

  add_foreign_key "endossos", "apolices", column: "apolice_numero", primary_key: "numero"
  add_foreign_key "endossos", "endossos", column: "endosso_cancelador_id"
  add_foreign_key "endossos", "endossos", column: "endosso_cancelamento_id"
end
