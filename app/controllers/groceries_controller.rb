class GroceriesController < ApplicationController

  def index
    @groceries = Grocery.all
    # @grocery = Grocery.find(params[:id])
  end

  def new
    @grocery = Grocery.new
  end

  def create
    @grocery = Grocery.new(grocery_params)
    if @grocery.save
      redirect_to groceries_path
    else
      render 'new'
    end
  end

  def edit
  end
  
  def show
  end

  private
  
  def grocery_params
    params.require(:grocery).permit(:ingredient, :category, :expired_date)
  end


end
