class GroceriesController < ApplicationController
  require 'ocr_space'

  def index
    
    @groceries = Grocery.all
    # @grocery = Grocery.find(params[:id])
  end

  def new
    @grocery = Grocery.new
  end

  def ocr_analyse
    file = img_params[:base64]
    data = OcrSpace::FilePost.post('/parse/image', body: { apikey: ENV['OCR_KEY'], language: 'eng', isOverlayRequired: true, base64Image: file })
    parsed_text = data.parsed_response['ParsedResults'][0]["ParsedText"].gsub(/\r|\n/, "")
    @result = date_algo(parsed_text)
    respond_to do |format|
      format.js {render :json => @result}
    end
  end

  def create
    @grocery = Grocery.new(grocery_params)
    @grocery.user_id = current_user.id
    if @grocery.save
      redirect_to groceries_path
    else
      render 'new'
    end
  end

  def edit
    @grocery = Grocery.find(params[:id])
  end

  def update
    @grocery = Grocery.find(params[:id])
    if @grocery.update(grocery_params)
      redirect_to groceries_path
    else
      render 'edit'
    end
  end

  def destroy
    @grocery = Grocery.find(params[:id])
    @grocery.destroy

    redirect_to groceries_path
  end
  
  def show
  end

  private
  
  def grocery_params
    params.require(:grocery).permit(:ingredient, :category, :expired_date)
  end

  # SET THE PARAMS TO RECEIVE AJAX REQUEST OF IMAGE DATA IN BASE64
  def img_params
    params.require(:image).permit(:base64)
  end

  # ALGORITHM TO INTELLIGENTLY FIND DATE
  def date_algo(parsed_text)
    # 1. CHECK IF THERE IS ANY RESULTS IF NOT THEN SKIP ALGORITHM
    expiry_date = ''
    if parsed_text.length > 5 
      text = parsed_text.gsub(/\s+/, '')
      combo1 = /(\d{4})\.\d{2}\.\d{2}/
      combo2 = /\d{2}\.\d{2}\.(\d{4})/
      combo3 = /\d{4}\.\d\.\d{2}/
      combo4 = /\d{2}\.\d\.\d{4}/
      combo5 = /\d{2}\w{3}\d{4}/
      combo6 = /\d{8}/
      combo7 = /\d{6}/

      if text.match?(combo1)
        result = combo1.match(text)
        if result[1].to_i < Date.today.year
          expiry_date = Date.parse(result[0][2..-1]).to_s
        else
          expiry_date = Date.parse(result.to_s).to_s
        end
      elsif text.match?(combo2)
        result = combo2.match(text)
        if result[1].to_i < Date.today.year
          expiry_date = Date.parse(result[0][0..7]).to_s
        else
          expiry_date = Date.parse(result.to_s).to_s
        end

      elsif text.match?(combo3)
        result = combo3.match(text)
        expiry_date = Date.parse(result.to_s).to_s

      elsif text.match?(combo4)
        result = combo4.match(text)
        expiry_date = Date.parse(result.to_s).to_s

      elsif text.match?(combo5)
        result = combo5.match(text)
        expiry_date = Date.parse(result.to_s).to_s

      elsif text.match?(combo6)
        result = combo6.match(text)
        expiry_date = Date.parse(result.to_s).to_s

      elsif text.match?(combo7)
        result = combo7.match(text)
        expiry_date = Date.parse(result.to_s).to_s
      end
     end

    if expiry_date == ''
      return expiry_date = {error: 1}
    else 
      return {date: expiry_date, error: 0}
    end
  end


end
