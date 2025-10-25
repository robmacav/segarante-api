require 'faker'

puts "🧹 Limpando base..."
Endosso.destroy_all
Apolice.destroy_all

puts "📄 Criando apólices de exemplo..."

10.times do
  data_emissao = Faker::Date.backward(days: 30)
  inicio_vigencia = data_emissao + rand(0..10).days
  fim_vigencia = inicio_vigencia + rand(100..365).days
  importancia = rand(50_000..500_000)
  lmg = importancia

  apolice = Apolice.create!(
    numero: "AP-#{Faker::Number.unique.number(digits: 8)}",
    data_emissao: data_emissao,
    inicio_vigencia: inicio_vigencia,
    fim_vigencia: fim_vigencia,
    importancia_segurada: importancia,
    lmg: lmg,
    status: 1
  )

  puts "🪪 Criando endossos para apólice #{apolice.numero}..."

  rand(5..10).times do |n|
    # Baseia-se no valor atual da apólice
    valor_atual = apolice.lmg

    # Define um tipo aleatório (aumento, redução ou vigência)
    tipo = %w[aumento_is reducao_is alteracao_vigencia aumento_is_alteracao_vigencia reducao_is_alteracao_vigencia].sample

    # Calcula uma nova importância segurada
    delta = rand(1_000..25_000)
    nova_importancia =
      case tipo
      when "aumento_is", "aumento_is_alteracao_vigencia"
        valor_atual + delta
      when "reducao_is", "reducao_is_alteracao_vigencia"
        [valor_atual - delta, 5_000].max # evita valores negativos
      else
        valor_atual
      end

    # Pode haver alterações de vigência também
    novo_fim = apolice.fim_vigencia

    if tipo.include?("vigencia")
      novo_fim = apolice.fim_vigencia + rand(30..120).days
    end

    # Cria o endosso
    endosso = apolice.endossos.create!(
      data_emissao: Faker::Date.between(from: apolice.data_emissao, to: Date.today),
      importancia_segurada: nova_importancia,
      fim_vigencia: novo_fim
    )

    # Atualiza a apólice com os novos valores vigentes
    apolice.update!(
      importancia_segurada: nova_importancia,
      lmg: nova_importancia,
      fim_vigencia: novo_fim
    )
  end
end

puts "✅ Criadas #{Apolice.count} apólices com #{Endosso.count} endossos totais."
