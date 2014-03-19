module Spree
  class MeasurementSetsController < Spree::StoreController
    before_action :set_measurement_set, only: [ :confirm, :action, :show, :edit, :update, :destroy]

   def confirm
      if @measurement_set.confirm!
        flash[:notice] = Spree.t('measurement_sets.confirm.success', number: @measurement_set.id)
      end
      redirect_to spree.edit_measurement_set_path(@measurement_set)
    end

    def action
      if @measurement_set.deliver!
        flash[:notice] = Spree.t('measurement_sets.action.success', number: @measurement_set.id)
      end
      redirect_to spree.edit_measurement_set_path(@measurement_set)
    end

    def update
      if @measurement_set.update_from_params(params)
        #persist_user_address      

        puts "params? in update action ////////// #{params }"
        unless @measurement_set.next
          flash[:error] = @measurement_set.errors.full_messages.join("\n")
          redirect_to measurement_set_edit_path(@measurement_set.state) and return
        end
        if @measurement_set.completed?
          session[:measurement_set_id] = nil
          flash.notice = Spree.t(:measurement_set_processed_successfully)
          redirect_to completion_route
        else
          redirect_to spree.edit_measurement_set_path(@measurement_set)
        end

      else
        render :edit
      end
    end


    def edit
      puts "params : #{params.inspect}"
    end

    def show
    end
 
    def new 
      @measurement_set = MeasurementSet.new

    end


    def create
      @measurement_set = MeasurementSet.new() #measurement_set_params
      bust = Measure.find_or_create_by_name( name: 'Bust', min: 3 , max: 50) 
      band = Measure.find_or_create_by_name( name: 'Band', min: 2 , max: 40) 
      item_bust = MeasureItem.create(measurement_set: @measurement_set, measure: bust, value: 0)  
      item_band = MeasureItem.create(measurement_set: @measurement_set, measure: band, value: 0)
      @measurement_set.customer = Spree::User.new()   
      if @measurement_set.save
        redirect_to spree.edit_measurement_set_path(@measurement_set)       
      else
        render action: 'new'      
      end
    end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_measurement_set
      puts "params /////////////////#{params.inspect}"
      @measurement_set = MeasurementSet.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
#    def measurement_set_params
#      params.require(:measurement_set)
#    end

    def completion_route
      spree.measurement_set_path(@measurement_set)
    end

  end

end