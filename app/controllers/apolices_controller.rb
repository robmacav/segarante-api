class ApolicesController < ApplicationController
  before_action :set_apolice, only: %i[ show ]

  def index
    @apolices = Apolice.all

    render json: @apolices.as_json
  end

def show
  render json: @apolice.as_json(
    only: [
      :numero,
      :data_emissao,
      :inicio_vigencia,
      :fim_vigencia_original,
      :fim_vigencia,
      :lmg_original,
      :lmg,
      :importancia_segurada_original,
      :importancia_segurada,
      :status
    ],
    include: {
      endossos: {
        only: [
          :id,
          :data_emissao,
          :importancia_segurada,
          :inicio_vigencia,
          :fim_vigencia,
          :endosso_cancelamento_id,
          :endosso_cancelador_id,
          :cancelando_endosso_id,
          :tipo
        ],
        methods: [:tipo_descricao]
      }
    }
  )
end


  def create
    @apolice = Apolice.new(apolice_params)

    if @apolice.save
      render json: @apolice, status: :created, location: @apolice
    else
      render json: @apolice.errors, status: :unprocessable_content
    end
  end

  private
    def set_apolice
      @apolice = Apolice.includes(:endossos).order(id: :asc).find_by(numero: params[:numero])
    end

    def apolice_params
      params.permit(:inicio_vigencia, :fim_vigencia, :importancia_segurada)
    end
end
