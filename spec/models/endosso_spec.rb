require 'rails_helper'

RSpec.describe Endosso, type: :model do
    describe 'Relacionamentos' do
        it 'Deve está relacionado a um registro de apólice' do
            should belong_to(:apolice)
        end

        it 'Deve se relacionar com um endosso cancelador (se for o caso)' do
            should belong_to(:cancelado_por_endosso).class_name('Endosso').optional
        end

        it 'Deve se relacionar com um endosso que foi cancelado (se for o caso)' do
            should belong_to(:cancelando_endosso).class_name('Endosso').optional
        end
    end

    describe 'Callbacks' do
        context 'before_validation on create' do

        end
    end

    describe 'Validação da geração de tipo #definir_tipo' do
        let(:apolice) do
            create(:apolice, inicio_vigencia: Date.new(2025, 1, 1), fim_vigencia: Date.new(2026, 1, 1), lmg: 10_000.0)
        end

        context 'Quando é cancelamento' do
            it 'Definir tipo como cancelamento' do
                endosso_cancelador = build(:endosso, apolice:, cancelado_por_endosso_id: 99)

                endosso_cancelador.valid?

                expect(endosso_cancelador.tipo).to eq('cancelamento')
            end
        end

        context 'Quando IS e vigência mudam' do
            it 'Definir tipo como aumento_is_alteracao_vigencia se IS aumenta (inicio_vigencia alterada)' do
                endosso = build(:endosso, apolice:, importancia_segurada: 12_000, inicio_vigencia: Date.new(2025, 2, 1))

                endosso.valid?

                expect(endosso.tipo).to eq('aumento_is_alteracao_vigencia')
            end

            it 'Definir tipo como aumento_is_alteracao_vigencia se IS aumenta (fim_vigencia alterada)' do
                endosso = build(:endosso, apolice:, importancia_segurada: 12_000, fim_vigencia: Date.new(2025, 2, 1))

                endosso.valid?

                expect(endosso.tipo).to eq('aumento_is_alteracao_vigencia')
            end

            it 'Definir tipo como reducao_is_alteracao_vigencia se IS reduz (fim_vigencia alterada)' do
                endosso = build(:endosso, apolice:, importancia_segurada: 8_000, fim_vigencia: Date.new(2025, 12, 31))

                endosso.valid?

                expect(endosso.tipo).to eq('reducao_is_alteracao_vigencia')
            end

            it 'Definir tipo como reducao_is_alteracao_vigencia se IS reduz (inicio_vigencia alterada)' do
                endosso = build(:endosso, apolice:, importancia_segurada: 8_000, inicio_vigencia: Date.new(2025, 12, 31))

                endosso.valid?

                expect(endosso.tipo).to eq('reducao_is_alteracao_vigencia')
            end
        end

        context 'Quando apenas IS muda' do
            it 'Definir tipo como aumento_is' do
                endosso = build(:endosso, apolice:, importancia_segurada: 15_000)

                endosso.valid?

                expect(endosso.tipo).to eq('aumento_is')
            end

            it 'Definir tipo como reducao_is' do
                endosso = build(:endosso, apolice:, importancia_segurada: 8_000)

                endosso.valid?

                expect(endosso.tipo).to eq('reducao_is')
            end
        end

        context 'Quando apenas a vigência muda' do
            it 'Definir tipo como alteracao_vigencia (inicio_vigencia alterada)' do
                endosso = build(:endosso, apolice:, inicio_vigencia: Date.new(2025, 2, 1))

                endosso.valid?

                expect(endosso.tipo).to eq('alteracao_vigencia')
            end

            it 'Definir tipo como alteracao_vigencia (fim_vigencia alterada)' do
                endosso = build(:endosso, apolice:, fim_vigencia: Date.new(2026, 2, 1))

                endosso.valid?
                
                expect(endosso.tipo).to eq('alteracao_vigencia')
            end
        end

        context 'Quando nada muda' do
            it 'Exibir alerta que nenhuma alteração foi detectada na apólice.' do
                endosso = build(:endosso, apolice:)

                endosso.valid?

                expect(endosso.errors[:base]).to include('Nenhuma alteração detectada na apólice.')
            end
        end
    end

    describe 'Validação de #fim_vigencia_nao_antes_do_inicio_da_apolice' do
        let(:apolice) { create(:apolice, inicio_vigencia: Date.new(2025, 1, 1)) }

        it 'Adicionar erro se fim_vigencia for anterior ao início da apólice' do
            endosso = build(:endosso, apolice:, fim_vigencia: Date.new(2024, 12, 31))

            endosso.valid?

            expect(endosso.errors[:fim_vigencia].first).to include('não pode ser anterior ao início da vigência da apólice')
        end

        it 'Não adicionar erro se fim_vigencia for posterior ou igual' do
            endosso = build(:endosso, apolice:, fim_vigencia: Date.new(2025, 1, 1))
            
            endosso.valid?
            
            expect(endosso.errors[:fim_vigencia]).to be_empty
        end
    end

    describe 'Validação de #inicio_vigencia_no_intervalo_de_30_dias_da_emissao' do
        let(:apolice) { create(:apolice) }

        it 'Adicionar erro se início_vigencia estiver mais de 30 dias antes da emissão' do
            endosso = build(:endosso, apolice:, data_emissao: Date.new(2025, 1, 31), inicio_vigencia: Date.new(2024, 12, 1))

            endosso.valid?

            expect(endosso.errors[:inicio_vigencia].first).to include('deve estar no máximo 30 dias antes ou depois da data de emissão')
        end

        it 'Adicionar erro se início_vigencia estiver mais de 30 dias depois da emissão' do
            endosso = build(:endosso, apolice:, data_emissao: Date.new(2025, 1, 1), inicio_vigencia: Date.new(2025, 2, 15))

            endosso.valid?

            expect(endosso.errors[:inicio_vigencia].first).to include('deve estar no máximo 30 dias antes ou depois da data de emissão')
        end

        it 'Não adicionar erro se o inicio_vigencia for até 30 dias depois da data_emissao' do
            endosso = build(:endosso, apolice:, data_emissao: Date.new(2025, 1, 1), inicio_vigencia: Date.new(2025, 1, 31))
            
            endosso.valid?
            
            expect(endosso.errors[:inicio_vigencia]).to be_empty
        end

        it 'Não adicionar erro se o inicio_vigencia for até 30 dias antes da data_emissao' do
            endosso = build(:endosso, apolice:, data_emissao: Date.new(2025, 1, 31), inicio_vigencia: Date.new(2025, 1, 1))
            
            endosso.valid?
            
            expect(endosso.errors[:inicio_vigencia]).to be_empty
        end
    end
end