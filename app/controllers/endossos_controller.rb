class EndossosController < ApplicationController
def create
  @endosso = Endosso.new(endosso_params)

  if @endosso.save
    render json: @endosso.as_json(
      only: [
        :apolice_numero,
        :data_emissao,
        :inicio_vigencia,
        :fim_vigencia,
        :importancia_segurada,
        :endosso_cancelamento_id,
        :endosso_cancelador_id,
        :tipo
      ],
      methods: [:tipo_descricao]
    ), status: :created
  else
    render json: @endosso.errors, status: :unprocessable_entity
  end
end



  private
    def endosso_params
      params.permit(:importancia_segurada, :fim_vigencia, :cancelando_endosso_id, :cancelamento, :apolice_numero)
    end
end
