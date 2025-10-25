class Endosso < ApplicationRecord
  belongs_to :apolice, class_name: 'Apolice', foreign_key: 'apolice_numero', primary_key: 'numero'
  # belongs_to :cancelador, class_name: 'Endosso', foreign_key: 'cancelado_por_endosso_id', optional: true

  scope :validos, -> { where(cancelado_por_endosso_id: nil) }

  enum :tipo, {
    aumento_is: 0,
    reducao_is: 1,
    alteracao_vigencia: 2,
    aumento_is_alteracao_vigencia: 3,
    reducao_is_alteracao_vigencia: 4,
    cancelamento: 5
  }

  DESCRICOES_TIPO = {
    "aumento_is" => "Aumenta a importância segurada (IS)",
    "reducao_is" => "Reduz a importância segurada (IS)",
    "alteracao_vigencia" => "Altera o período de vigência",
    "aumento_is_alteracao_vigencia" => "Aumenta a IS e altera a vigência",
    "reducao_is_alteracao_vigencia" => "Reduz a IS e altera a vigência",
    "cancelamento" => "Cancela o último endosso válido"
  }.freeze

  def tipo_descricao
    DESCRICOES_TIPO[self.tipo]
  end

  validate :fim_vigencia_nao_antes_do_inicio_da_apolice

  before_validation :definir_tipo
  before_validation :definir_data_emissao
  after_create :atualizar_valor_is_apolice, if: :importancia_segurada?
  # after_create :cancelar_ultimo_endosso_valido, if: :cancelamento?

  private

  def definir_tipo
    puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    puts "self: #{self.inspect}"
    puts "apolice: #{self.apolice}"
    puts "valor atual: #{apolice&.importancia_segurada&.to_f}, novo valor: #{importancia_segurada&.to_f}"
    puts "vigencia atual: #{apolice&.fim_vigencia}, nova vigencia: #{fim_vigencia}"
    puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

    is_mudou = importancia_segurada.present? && importancia_segurada != apolice.importancia_segurada

    vigencia_mudou = fim_vigencia&.present? && fim_vigencia != apolice&.fim_vigencia

    if cancelando_endosso_id.present?
      self.tipo = :cancelamento
    elsif is_mudou && vigencia_mudou
      if importancia_segurada > apolice.importancia_segurada
        self.tipo = :aumento_is_alteracao_vigencia
      else
        self.tipo = :reducao_is_alteracao_vigencia
      end
    elsif is_mudou
      self.tipo = importancia_segurada > apolice.importancia_segurada ? :aumento_is : :reducao_is
    elsif vigencia_mudou
      self.tipo = :alteracao_vigencia
    else
      errors.add(:endosso, "Nenhuma alteração detectada na apólice.")

      throw(:abort)
    end
  end

  def atualizar_valor_is_apolice
    apolice.update!(importancia_segurada: importancia_segurada)
  end

  def cancelar_ultimo_endosso_valido
    ActiveRecord::Base.transaction do
      ultimo_endosso_valido = apolice.endossos
                                     .validos
                                     .order(data_emissao: :desc)
                                     .first

      unless ultimo_endosso_valido
        errors.add(:endosso, "Nenhum endosso válido encontrado para cancelar para a apólice #{apolice.numero}.")

        raise ActiveRecord::Rollback
      end

      ultimo_endosso_valido.update!(cancelado_por_endosso_id: id)

      novo_endosso_valido = apolice.endossos.validos.order(data_emissao: :desc).first

      if novo_endosso_valido
        apolice.update!(
          importancia_segurada: novo_endosso_valido.importancia_segurada,
          lmg: novo_endosso_valido.importancia_segurada, # mantém coerência do LMG
          fim_vigencia: novo_endosso_valido.fim_vigencia
        )
      else
        apolice.update!(
          importancia_segurada: apolice.importancia_segurada_original,
          lmg: apolice.lmg_original,
          fim_vigencia: apolice.fim_vigencia_original,
          status: :baixada
        )
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Erro ao processar cancelamento de endosso #{id}: #{e.message}")
    raise ActiveRecord::Rollback
  end

  def fim_vigencia_nao_antes_do_inicio_da_apolice
    return if apolice.nil? || fim_vigencia.nil? || apolice.inicio_vigencia.nil?

    if fim_vigencia < apolice.inicio_vigencia
      errors.add(:fim_vigencia, "não pode ser anterior ao início da vigência da apólice (#{apolice.inicio_vigencia.strftime('%d/%m/%Y')})")
    end
  end

  def cancelamento?
    cancelamento.to_s.downcase == 'true'
  end
end
