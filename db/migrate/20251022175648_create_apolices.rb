class CreateApolices < ActiveRecord::Migration[8.0]
  def change
    create_table :apolices do |t|
      t.bigint :numero, null: false
      t.date :data_emissao, null: false
      t.date :inicio_vigencia, null: false
      t.date :fim_vigencia, null: false
      t.decimal :importancia_segurada, precision: 15, scale: 2, null: false
      t.decimal :lmg, precision: 15, scale: 2, null: false
      t.date :fim_vigencia_original, null: false
      t.decimal :importancia_segurada_original, precision: 15, scale: 2, null: false
      t.decimal :lmg_original, precision: 15, scale: 2, null: false
      t.integer :status, null: false
    end

    add_index :apolices, :numero, unique: true
  end
end
