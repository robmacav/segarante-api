class Apolice < ApplicationRecord
    validates :inicio_vigencia, :fim_vigencia, presence: { message: 'a data deve ser obrigatoriamente informada.' }
    validates :importancia_segurada, presence: { message: 'o valor deve ser obrigatoriamente informado.' }
    validates :importancia_segurada, numericality: { greater_than: 0, message: "o valor deve ser maior que zero." }

    has_many :endossos, -> { order(id: :desc) }, class_name: 'Endosso', foreign_key: :apolice_numero, primary_key: :numero

    scope :endossos_validos, -> { endossos.where(endosso_cancelador_id: nil, endosso_cancelamento_id: nil ) }

    enum :status, { baixada: 0, ativa: 1 }

    def ultimo_endosso_valido
        endossos.where(endosso_cancelador_id: nil, endosso_cancelamento_id: nil).order(id: :desc).first
    end

    validate :fim_vigencia_posterior_ao_inicio
    validate :inicio_vigencia_no_intervalo_de_30_dias_da_emissao

    before_save :sincronizar_lmg_com_importancia_segurada
    before_create :definir_ativa, :definir_importancia_segurada__lmg__fim_vigencia_original
    before_validation :definir_data_emissao, :gerar_numero_automatico, on: :create

    private

    def definir_importancia_segurada__lmg__fim_vigencia_original
        self.lmg_original = importancia_segurada
        self.fim_vigencia_original = fim_vigencia
        self.importancia_segurada_original = importancia_segurada
    end

    def sincronizar_lmg_com_importancia_segurada
        self.lmg = importancia_segurada
    end

    def definir_ativa
        self.status = :ativa
    end

    def gerar_numero_automatico
        ano_mes = Date.today.strftime("%Y%m")

        ultima_apolice_numero = Apolice.all.map(&:numero).sort[-1]

        ultima_sequencia =
            if ultima_apolice_numero 
                ultima_apolice_numero .to_s[-6..-1].to_i
            else
                0
            end

        nova_sequencia = ultima_sequencia + 1

        self.numero = (ano_mes + format("%06d", nova_sequencia)).to_i
    end

    def fim_vigencia_posterior_ao_inicio
        return if inicio_vigencia.blank? || fim_vigencia.blank?

        if fim_vigencia < inicio_vigencia
            errors.add(:fim_vigencia, "não pode ser anterior ao início da vigência.")
        end
    end

    def inicio_vigencia_no_intervalo_de_30_dias_da_emissao
        return if inicio_vigencia.blank? || data_emissao.blank?
        
        dias_diff = (inicio_vigencia - data_emissao).to_i

        if dias_diff.abs > 30
            errors.add(:inicio_vigencia, "deve estar no máximo 30 dias antes ou depois da data de emissão (#{data_emissao.strftime('%d/%m/%Y')})")
        end
    end
end
