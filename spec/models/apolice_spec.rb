require 'rails_helper'

RSpec.describe Apolice, type: :model do
  describe 'Validações' do
    it 'Data de inicio da vigência deve ser obritatório o preenchimento' do
      should validate_presence_of(:inicio_vigencia).with_message('a data deve ser obrigatoriamente informada.')
    end

    it 'Data do fim da vigẽncia deve ser obrigatório o preenchimento' do
      should validate_presence_of(:fim_vigencia).with_message('a data deve ser obrigatoriamente informada.')
    end

    it 'O Valor da Importancia Segurada deve ser obrigatório o preenchimento e maior que zero' do
      should validate_presence_of(:importancia_segurada).with_message('o valor deve ser obrigatoriamente informado.')
      should validate_numericality_of(:importancia_segurada).is_greater_than(0).with_message('o valor deve ser maior que zero.')
    end
  end

  describe 'validações de vigência' do
    let(:inicio_vigencia) { Date.today }
    let(:fim_vigencia_valido) { Date.today + 10.days }
    let(:fim_vigencia_invalido) { Date.today - 5.days }

    context 'quando fim_vigencia é posterior ao início' do
      it 'é válida' do
        apolice = Apolice.new(
          inicio_vigencia: inicio_vigencia,
          fim_vigencia: fim_vigencia_valido,
          importancia_segurada: 1000
        )

        expect(apolice).to be_valid
      end
    end

    context 'quando fim_vigencia é anterior ao início' do
      it 'não é válida e adiciona erro em fim_vigencia' do
        apolice = Apolice.new(
          inicio_vigencia: inicio_vigencia,
          fim_vigencia: fim_vigencia_invalido,
          importancia_segurada: 1000
        )

        expect(apolice).not_to be_valid
        expect(apolice.errors[:fim_vigencia])
          .to include("não pode ser anterior ao início da vigência.")
      end
    end
  end

  describe 'Relacionamentos' do
    it 'Deve possuir muitos endossos ordenados pela data_emissao decrescente (mais recentes primeiro)' do
      should have_many(:endossos).order(data_emissao: :desc)
    end
  end

  describe 'Callbacks' do
    context 'before_validation on create' do
      it 'Preencher automaticamente a data_emissao com a data corrente' do
        apolice = build(:apolice)
        
        expect(apolice.data_emissao).to be_nil

        apolice.save!

        expect(apolice.data_emissao).to eq(Date.today)
      end

      it 'Gerar automaticamente um numero de identificação' do
        apolice = build(:apolice)
        
        expect(apolice.numero).to be_nil

        apolice.save!

        expect(apolice.numero).to match(/^#{Date.today.strftime("%Y%m")}\d{6}$/)
      end
    end
  end

  describe 'Escopos' do
    context 'Padrões' do
      it 'Ordena por padrão via data_emissao em ordem decrescente (mais recentes primeiro)' do
        apolice1 = create(:apolice)
        apolice2 = create(:apolice)

        apolice1.update!(data_emissao: Date.today - 10)
        apolice2.update!(data_emissao: Date.today)

        apolices = Apolice.all

        expect(apolices.first).to eq(apolice2)
        expect(apolices.last).to eq(apolice1)
      end
    end
  end

  describe 'Enum' do
    context 'Status' do
      it 'Deve existir os status de baixada e ativa' do
        expect(described_class.statuses).to eq({ 'baixada' => 0, 'ativa' => 1 })
      end
    end
  end
end
