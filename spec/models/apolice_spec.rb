require 'rails_helper'

RSpec.describe Apolice, type: :model do
  describe 'validações' do
    context 'validação de presença' do
      it 'É inválida sem inicio_vigencia' do
        apolice = build(:apolice, inicio_vigencia: nil)

        expect(apolice).not_to be_valid

        expect(apolice.errors[:inicio_vigencia]).to include('a data deve ser obrigatoriamente informada.')
      end

      it 'É inválida sem fim_vigencia' do
        apolice = build(:apolice, fim_vigencia: nil)

        expect(apolice).not_to be_valid

        expect(apolice.errors[:fim_vigencia]).to include('a data deve ser obrigatoriamente informada.')
      end

      it 'É inválida sem importancia_segurada' do
        apolice = build(:apolice, importancia_segurada: nil)

        expect(apolice).not_to be_valid

        expect(apolice.errors[:importancia_segurada]).to include('o valor deve ser obrigatoriamente informado.')
      end
    end

    context 'Validação da Importância Segurada' do
      it 'É inválida quando é zero' do
        apolice = build(:apolice, importancia_segurada: 0)

        expect(apolice).not_to be_valid

        expect(apolice.errors[:importancia_segurada]).to include('o valor deve ser maior que zero.')
      end

      it 'É inválida quando é negativa' do
        apolice = build(:apolice, importancia_segurada: -1000)

        expect(apolice).not_to be_valid

        expect(apolice.errors[:importancia_segurada]).to include('o valor deve ser maior que zero.')
      end
    end

    context 'Validação de vigência' do
      let(:inicio_vigencia) { Date.today }
      let(:fim_vigencia_valido) { Date.today + 10.days }
      let(:fim_vigencia_invalido) { Date.today - 5.days }

      it 'É válida quando fim_vigencia é posterior ao início' do
        apolice = build(:apolice, inicio_vigencia: inicio_vigencia, fim_vigencia: fim_vigencia_valido)

        expect(apolice).to be_valid
      end

      it 'É inválida quando fim_vigencia é anterior ao início' do
        apolice = build(:apolice, inicio_vigencia: inicio_vigencia, fim_vigencia: fim_vigencia_invalido)

        expect(apolice).not_to be_valid

        expect(apolice.errors[:fim_vigencia]).to include('não pode ser anterior ao início da vigência.')
      end
    end

    context 'Validação do intervalo entre data_emissao e início_vigência' do
      let(:data_emissao) { Date.today }

      it 'É válida se inicio_vigencia estiver até 30 dias antes da data_emissao' do
        apolice = build(:apolice, data_emissao: data_emissao, inicio_vigencia: data_emissao - 30.days)

        expect(apolice).to be_valid
      end

      it 'É válida se inicio_vigencia estiver até 30 dias depois da data_emissao' do
        apolice = build(:apolice, data_emissao: data_emissao, inicio_vigencia: data_emissao + 30.days)

        expect(apolice).to be_valid
      end

      it 'É inválida se inicio_vigencia for mais de 30 dias antes da data_emissao' do
        apolice = build(:apolice, data_emissao: data_emissao, inicio_vigencia: data_emissao - 31.days)

        expect(apolice).not_to be_valid
        
        expect(apolice.errors[:inicio_vigencia].first).to include('deve estar no máximo 30 dias antes ou depois da data de emissão')
      end

      it 'É inválida se inicio_vigencia for mais de 30 dias depois da data_emissao' do
        apolice = build(:apolice, data_emissao: data_emissao, inicio_vigencia: data_emissao + 31.days)

        expect(apolice).not_to be_valid

        expect(apolice.errors[:inicio_vigencia].first).to include('deve estar no máximo 30 dias antes ou depois da data de emissão')
      end
    end
  end

  describe 'callbacks' do
    context 'before_create' do
      it 'Deve definir o status como ativa' do
        apolice = create(:apolice, status: nil)

        expect(apolice.status).to eq('ativa')
      end

      it 'Deve definir os campos originais corretamente' do
        apolice = create(:apolice, importancia_segurada: 10_000, fim_vigencia: Date.today + 1.year)

        expect(apolice.lmg_original).to eq(10_000)

        expect(apolice.importancia_segurada_original).to eq(10_000)

        expect(apolice.fim_vigencia_original).to eq(apolice.fim_vigencia)
      end
    end

    context 'before_save' do
      it 'Deve sincronizar lmg com importancia_segurada' do
        apolice = create(:apolice, importancia_segurada: 8000, lmg: nil)

        expect(apolice.lmg).to eq(8000)
      end
    end

    context 'before_validation on create' do
      it 'Deve gerar automaticamente um número de identificação sempre único' do
        apolice = build(:apolice)

        expect(apolice.numero).to be_nil

        apolice.save!

        expect(apolice.numero.to_s).to match(/^#{Date.today.strftime("%Y%m")}\d{6}$/)
      end
    end
  end

  describe 'Associações' do
    it 'Deve se relacionar com nenhum, um ou vários endossos' do
      is_expected.to have_many(:endossos).with_foreign_key(:apolice_numero).order(id: :desc)
    end
  end

  describe 'Enum' do
    it 'Deve possui status baixada e ativa' do
      expect(described_class.statuses.keys).to contain_exactly('baixada', 'ativa')
    end
  end

  describe '#ultimo_endosso_valido' do
    it 'Deve retornar o endosso mais recente sem cancelamento' do
      apolice = create(:apolice, numero: 123)

      endosso1 = double('Endosso', id: 1, endosso_cancelador_id: nil, endosso_cancelamento_id: nil)
      endosso2 = double('Endosso', id: 2, endosso_cancelador_id: nil, endosso_cancelamento_id: nil)

      relation_mock = double('ActiveRecord::Relation')

      allow(apolice).to receive(:endossos).and_return(relation_mock)

      allow(relation_mock).to receive(:where).with(endosso_cancelador_id: nil, endosso_cancelamento_id: nil).and_return(relation_mock)

      allow(relation_mock).to receive(:order).with(id: :desc).and_return([endosso2, endosso1])

      expect(apolice.ultimo_endosso_valido).to eq(endosso2)
    end
  end
end
