module Spree
  class MeasurementSet < ActiveRecord::Base
    belongs_to :seller, :class_name => "User"
    belongs_to :customer, :class_name => "User"
    has_many :measure_items, dependent: :destroy

    accepts_nested_attributes_for :measure_items, :allow_destroy => true

    #==========================================
    # State Machine

    state_machine :initial => :active do
      
      after_transition :on => :address, :do => :perform_address
      after_transition :on => :bust, :do => :perform_bust
      after_transition :on => :band, :do => :perform_band 
      after_transition :on => :confirm, :do => :perform_confirmation
      after_transition :on => :complete, :do => :perform_complete
    
      event :address do 
        transition [ :active, :address ] => :address
      end
      event :bust do 
        transition [ :active,  :address ] => :bust
      end
      event :band do 
        transition [ :active, :address, :bust ] => :band
      end
      event :confirm do
        transition [ :active,  :address, :bust, :band ] => :confirm
      end
      event :complete do
        transition [ :active,  :address, :bust, :band, :confirm ] => :completed
      end

    end

    #==========================================
    # Methods

    def prev    
      case state
      when 'active' then return nil
      when 'address' then return 'active'
      when 'bust' then return 'address'
      when 'band' then return 'bust'
      when 'confirm' then return 'band'
      when 'completed' then return 'confirm'
      end   
      return false
    end

    def next
      case state
      when 'active' then return self.address!
      when 'address' then return self.bust!
      when 'bust' then return self.band!
      when 'band' then return self.confirm!
      when 'confirm' then return self.complete! 
      end   
      return false
    end

    def update_from_params(params)     
      attributes = {}
      attributes = params[:measurement_set] if params[:measurement_set].present?
      
      if attributes[:measure_item].present?              
        measure = Spree::Measure.find_by_name(params[:state].capitalize)
        measure_items.each do |measure_item|
          if measure_item.measure.id == measure.id
             unless measure_item.update_attributes(:value => attributes[:measure_item][:value]) 
               errors.add(:base, 'Invalid measurement value.') and return false
             end
          end  
        end
      end

      if attributes[:measure_items_attributes].present?
         attributes[:measure_items_attributes].each do |key, hash_value |           
          measure_item = measure_items[key.to_i]        
          unless measure_item.update_attributes(:value =>  hash_value[:value])
            errors.add(:base, 'Invalid field.') and return false           
          end                   
        end
      end

      if attributes[:new_user].present? && attributes[:new_user][:email].present?   
        if customer.nil?
          gp = generate_password
          params[:measurement_set][:new_user][:password] = gp
          params[:measurement_set][:new_user][:password_confirmation] = gp   
          user = Spree.user_class.new new_user_set_params(params)
          unless user.save
            errors.add(:base, 'Invalid email.') and return false
          end
          self.customer = user
        else
          return false unless customer.id = attributes[:new_user][:email]
        end                                               
      end
    
      if attributes[:user].present? && attributes[:user][:id].present?     
          return false unless self.customer = Spree::User.find(attributes[:user][:id])
      end

      if attributes[:ship_address].present?
        if self.customer.ship_address
          unless self.customer.ship_address.update_attributes address_set_params(params) 
            errors.add(:base, 'Invalid Address Field') and return false
          end
        else
          address = Spree::Address.new address_set_params(params)
          unless address.save
            errors.add(:base, 'Invalid address fields.') and return false
          end
          self.customer.ship_address = address      
          self.customer.save            
        end 
      end      
      return self.save
    end

  private

    def perform_address 
      self.update_attribute(:action_at, Time.now)
    end

    def perform_bust 
      self.update_attribute(:action_at, Time.now)
    end

    def perform_band 
      self.update_attribute(:action_at, Time.now)
    end

    def perform_confirmation 
      self.update_attribute(:confirmed_at, Time.now)
    end

    def perform_complete 
      self.update_attribute(:completed_at, Time.now)
    end

    def new_user_set_params(params)
      params.require(:measurement_set).require(:new_user).permit( :email,:password, :password_confirmation) 
    end
   
    def user_set_params(params)
      params.require(:measurement_set).require(:user).permit( :email)
    end

    def address_set_params(params)
      params.require(:measurement_set).require(:ship_address).permit( :firstname, :lastname, :address1, :address2, :city, :country_id, :state_id, :zipcode, :phone )
    end

    #TODO: improve gerations.
    def generate_password    
      "123456"
    end

  end
end
