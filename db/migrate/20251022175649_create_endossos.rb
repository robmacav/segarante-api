class CreateEndossos < ActiveRecord::Migration[7.0]
  def change
    create_table :endossos do |t|
        t.date :data_emissao, null: false
        t.date :fim_vigencia
        t.decimal :importancia_segurada, precision: 15, scale: 2
        t.references :endosso_cancelador, foreign_key: { to_table: :endossos }
        t.references :endosso_cancelamento, foreign_key: { to_table: :endossos }
        t.integer :tipo, null: false, default: 0
        t.bigint :apolice_numero, null: false
    end

    add_index :endossos, :apolice_numero
    add_foreign_key :endossos, :apolices, column: :apolice_numero, primary_key: :numero
  end
end
