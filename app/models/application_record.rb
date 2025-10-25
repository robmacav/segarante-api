class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  
  def definir_data_emissao
    self.data_emissao = Date.today
  end
end
