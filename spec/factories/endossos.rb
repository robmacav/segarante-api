FactoryBot.define do
  factory :endosso do
    association :apolice
    importancia_segurada { nil }
    fim_vigencia { nil }
    cancelamento { false }
    endosso_cancelamento_id { nil }
    endosso_cancelador_id { nil }
  end
end
