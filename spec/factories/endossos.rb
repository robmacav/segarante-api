FactoryBot.define do
  factory :endosso do
    association :apolice
    importancia_segurada { nil }
    inicio_vigencia { nil }
    fim_vigencia { nil }
    cancelado_por_endosso_id { nil }
  end
end
