FactoryBot.define do
  factory :apolice do
    inicio_vigencia { Date.today }
    fim_vigencia { Date.today + 1.year }
    importancia_segurada { rand(5_000.0..50_000.0) }
  end
end
