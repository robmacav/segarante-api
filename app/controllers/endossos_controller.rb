class EndossosController < ApplicationController
def create
  @endosso = Endosso.new(endosso_params)

  endosso_anterior = Endosso.where(apolice_numero: @endosso.apolice_numero).last

  if endosso_anterior.present?
    fim_vigencia_atual = @endosso.fim_vigencia || @endosso.apolice&.fim_vigencia
    is_atual = @endosso.importancia_segurada || @endosso.apolice&.importancia_segurada

    fim_vigencia_anterior = endosso_anterior.fim_vigencia.presence || @endosso.apolice&.fim_vigencia
    importancia_anterior   = endosso_anterior.importancia_segurada.presence || @endosso.apolice&.importancia_segurada
  else
    fim_vigencia_atual = @endosso.fim_vigencia || @endosso.apolice&.fim_vigencia
    is_atual = @endosso.importancia_segurada || @endosso.apolice&.importancia_segurada

    apolice = @endosso.apolice
    fim_vigencia_anterior = apolice&.fim_vigencia
    importancia_anterior   = apolice&.importancia_segurada
  end

  if @endosso.save
    render json: {
      apolice: {
        numero: @endosso.apolice.numero,
        fim_vigencia_anterior: fim_vigencia_anterior,
        fim_vigencia_atual: fim_vigencia_atual,
        importancia_segurada_anterior: importancia_anterior,
        importancia_segurada_atual: is_atual
      },
      tipo_endosso: @endosso.tipo,
      data_emissao: @endosso.data_emissao
    }, status: :created
  else
    render json: @endosso.errors, status: :unprocessable_entity
  end
end


  private
    def endosso_params
      params.permit(:importancia_segurada, :fim_vigencia, :cancelando_endosso_id, :cancelamento, :apolice_numero)
    end
end
