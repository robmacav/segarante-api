require 'rails_helper'

RSpec.describe Endosso, type: :model do
  describe 'Associações' do
    it 'Deve está vinculado a uma apólice' do
      is_expected.to belong_to(:apolice).optional
    end

    it 'Deve ser possível se relacionar a um endosso que foi cancelado' do
        is_expected.to belong_to(:endosso_cancelado).optional
    end
    
    it 'Deve ser possível se relacionar com endosso que foi responsável pelo seu cancelamento' do 
        is_expected.to belong_to(:endosso_cancelador).optional
    end
  end

  describe 'Enums' do
    it 'Deve possuir os 6 tipos de endosso definidos corretamente' do
      expect(described_class.tipos.keys).to contain_exactly(
        'aumento_is',
        'reducao_is',
        'alteracao_vigencia',
        'aumento_is_alteracao_vigencia',
        'reducao_is_alteracao_vigencia',
        'cancelamento'
      )
    end

    it 'Deve retornar a descrição correta para cada tipo' do
      endosso = build(:endosso)

      Endosso::DESCRICOES_TIPO.each do |tipo, descricao|
        endosso.tipo = tipo
        expect(endosso.tipo_descricao).to eq(descricao)
      end
    end
  end

  describe 'Validações' do
    context 'Validação de vigência' do
      it 'É inválido se fim_vigencia for anterior ao início da apólice' do
        apolice = create(:apolice, inicio_vigencia: Date.today)
        endosso = build(:endosso, apolice: apolice, fim_vigencia: Date.today - 5.days)

        expect(endosso).not_to be_valid
        expect(endosso.errors[:fim_vigencia].first).to include('não pode ser anterior ao início da vigência da apólice')
      end

      it 'É válido quando fim_vigencia é posterior ao início da apólice' do
        apolice = create(:apolice, inicio_vigencia: Date.today)
        endosso = build(:endosso, apolice: apolice, fim_vigencia: Date.today + 10.days)

        expect(endosso).to be_valid
      end
    end
  end

  describe 'Callbacks' do
    context 'before_validation' do
        it 'Garantir que o endosso gerado tenha o espelho dos dados da apólice naquele momento' do
            apolice = create(:apolice, importancia_segurada: 5000, fim_vigencia: Date.today + 1.year)
            endosso = build(:endosso, apolice: apolice, importancia_segurada: nil, fim_vigencia: nil)

            endosso.send(:replicar_valores_apolice)
            
            endosso.valid?

            expect(endosso.importancia_segurada).to eq(5000)
            expect(endosso.fim_vigencia).to eq(apolice.fim_vigencia)
        end

      it 'Define o tipo como aumento_is quando aumentar a IS' do
        apolice = create(:apolice, importancia_segurada: 5000)
        endosso = build(:endosso, apolice: apolice, importancia_segurada: 8000)

        endosso.valid?

        expect(endosso.tipo).to eq('aumento_is')
      end

      it 'Definir o tipo como reducao_is quando reduzir a IS' do
        apolice = create(:apolice, importancia_segurada: 8000)
        endosso = build(:endosso, apolice: apolice, importancia_segurada: 5000)

        endosso.valid?

        expect(endosso.tipo).to eq('reducao_is')
      end

      it 'Definir o tipo como alteracao_vigencia quando só a vigência mudar' do
        apolice = create(:apolice, fim_vigencia: Date.today + 30.days)
        endosso = build(:endosso, apolice: apolice, fim_vigencia: Date.today + 60.days)

        endosso.valid?

        expect(endosso.tipo).to eq('alteracao_vigencia')
      end

      it 'Definir o tipo como aumento_is_alteracao_vigencia quando IS e vigência aumentar' do
        apolice = create(:apolice, importancia_segurada: 5000, fim_vigencia: Date.today + 30.days)
        endosso = build(:endosso, apolice: apolice, importancia_segurada: 8000, fim_vigencia: Date.today + 60.days)

        endosso.valid?

        expect(endosso.tipo).to eq('aumento_is_alteracao_vigencia')
      end

      it 'Definir o tipo como reducao_is_alteracao_vigencia quando IS reduzir e vigência mudar' do
        apolice = create(:apolice, importancia_segurada: 8000, fim_vigencia: Date.today + 30.days)
        endosso = build(:endosso, apolice: apolice, importancia_segurada: 5000, fim_vigencia: Date.today + 60.days)

        endosso.valid?

        expect(endosso.tipo).to eq('reducao_is_alteracao_vigencia')
      end
    end

    context 'after_create' do
      it 'Atualizar a IS da apólice após criação de endosso com novo valor' do
        apolice = create(:apolice, importancia_segurada: 5000)
        endosso = create(:endosso, apolice: apolice, importancia_segurada: 8000)

        expect(apolice.reload.importancia_segurada).to eq(8000)
      end
    end
  end

  describe '#cancelamento' do
    context 'Quando é um endosso de cancelamento' do
      it 'Deve definir o tipo como cancelamento e associar o endosso a ser cancelado' do
        apolice = create(:apolice)
        endosso_anterior = create(:endosso, apolice: apolice, importancia_segurada: 7000)

        allow(apolice).to receive(:ultimo_endosso_valido).and_return(endosso_anterior)

        endosso = build(:endosso, apolice: apolice, cancelamento: true)

        endosso.valid?

        expect(endosso.tipo).to eq('cancelamento')

        expect(endosso.endosso_cancelamento_id).to eq(endosso_anterior.id)
      end

      it 'Não deve permitir o cancelamento se não houver endosso válido' do
        apolice = create(:apolice)

        allow(apolice).to receive(:ultimo_endosso_valido).and_return(nil)

        endosso = build(:endosso, apolice: apolice, cancelamento: true)

        expect { endosso.valid? }.to change { endosso.errors[:endosso] }.from([]).to(
          include("Nenhum endosso válido encontrado para cancelar para a apólice #{apolice.numero}.")
        )
      end
    end
  end
end
