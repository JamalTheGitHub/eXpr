class GroceriesController < ApplicationController
  require 'ocr_space'

  def index
    recipe_key = ENV["FOOD2FORK"]

    @groceries = Grocery.all.order(:expired_date)
  end

  def new
    if params[:item] && params[:expiry_date]
      @voice_preset_new = {item: params[:item].titleize, expiry_date: params[:expiry_date]}
    elsif params[:item]
      @voice_preset_new = {item: params[:item].titleize}
    elsif params[:expiry_date]
      @voice_preset_new = {expiry_date: params[:expiry_date]}
    end

    @grocery = Grocery.new
  end
  
  def create
    @grocery = Grocery.new(grocery_params)
    @grocery.user_id = current_user.id
    if @grocery.save
      redirect_to user_groceries_path
    else
      render 'new'
    end
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
  
  def voice_analyse
    voice_to_text = voice_params[:value]
    @result_hash = item_date_algo(voice_to_text)
    respond_to do |format|
      format.js {render :json => @result_hash}
    end
  end
  
  def edit
    @grocery = Grocery.find(params[:id])
  end
  
  def update
    @grocery = Grocery.find(params[:id])
    if @grocery.update(grocery_params)
      redirect_to user_groceries_path
    else
      render 'edit'
    end
  end
  
  def destroy
    @grocery = Grocery.find(params[:id])
    @grocery.destroy
    
    redirect_to user_groceries_path
  end
  
  def show
    recipe_key = ENV["FOOD2FORK"]
    
    @groceries = Grocery.all
    @grocery = Grocery.find(params[:id])
  end
  
  def show_ingredients
    @groceries = User.find(params[:user_id]).groceries.order(:expired_date)
    @valid_items = []
    @groceries.each do |grocery|
      if grocery.show_valid_items? == true
      @valid_items << grocery
      end
    end
  end
  
  def recipes
    
    ingredients = recipe_params.join(',')
    @recipes = Food2Fork::Recipe.search({q: ingredients, sort: 'r', page: 3})
    
    render 'result'
  end

  def expiries
    groceries = User.find(params[:user_id]).groceries.order(:expired_date)
    @exps = []
    groceries.each do |grocery|
      if grocery.expiring_within_3days? == true
        @exps << grocery
      end
    end
  end

  def expired
    groceries = User.find(params[:user_id]).groceries.order(:expired_date)
    @expired = []
    groceries.each do |grocery|
      if grocery.expired? == true
        @expired << grocery
      end
    end
  end

  private
  
  def grocery_params
    params.require(:grocery).permit(:ingredient, :expired_date)
  end
  
  def recipe_params
    params.require(:recipe).permit(ingredients:[])[:ingredients]
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
        result = combo1.match(text)[0]
        if result[1].to_i < Date.today.year
          expiry_date = Date.parse(result[2..-1]).to_s
        else
          expiry_date = Date.parse(result).to_s
        end
      elsif text.match?(combo2)
        result = combo2.match(text)[0]
        if result[1].to_i < Date.today.year
          expiry_date = Date.parse(result[0..7]).to_s
        else
          expiry_date = Date.parse(result).to_s
        end

      elsif text.match?(combo3)
        result = combo3.match(text)[0]
        expiry_date = Date.parse(result).to_s

      elsif text.match?(combo4)
        result = combo4.match(text)[0]
        expiry_date = Date.parse(result).to_s

      elsif text.match?(combo5)
        result = combo5.match(text)[0]
        expiry_date = Date.parse(result).to_s

      elsif text.match?(combo6)
        result = combo6.match(text)[0]
        expiry_date = Date.parse(result).to_s

      elsif text.match?(combo7)
        result = combo7.match(text)[0]
        expiry_date = Date.parse(result).to_s
      end
     end

    if expiry_date == ''
      return expiry_date = {error: 1}
    else 
      return {date: expiry_date, error: 0}
    end
  end

  # VOICE RECOGNITION 
  # SET PARAMS TO RECEIVE AJAX REQUEST OF VOICE DATA
  def voice_params
    params.require(:text).permit(:value)
  end

  # ALGORITHM TO INTELLIGENTLY UNDERSTAND TEXT
  def item_date_algo(parsed_text)
    # 'energy bar 12th November 2020'
    # 'pineapple 6th of July 2018'
    # 'raw fish 5th July 2018'
    # 'junk food 11th of May 2019'
    # 'junk food 11 May 2019'
    # 'watermelon 23rd of January 2023'
    # ' raw pork tomorrow'
    # 'Orange next week'
    # ' egg 3 days'


    # DDth(month)YYYY || DD(month)YYYY || Dth(month)YYYY
    months = Date::MONTHNAMES.compact
    item_date = /\d{1,2}(st|nd|rd|th)?(\s?(Of)?)\s(#{months.join('|')})(\s\d{4})?/
    date_only = /^\d{1,2}(st|nd|rd|th)?(\s?(Of)?)\s(#{months.join('|')})(\s\d{4})?$/
    item_tmr = /(Expiring\s)?Tomorrow/
    item_days = /(Expiring\sIn\s)?(\d{1,2})\sDays/
    

    # Capitalises all first character of words only
    text = parsed_text.titleize

    if text.match?(date_only)
      result = text.match(date_only)[0]
      expiry_date = Date.parse(result).to_s
    elsif text.match?(item_date)
      result = text.match(item_date)[0]
      item_name = text.chomp(result).strip
      expiry_date = Date.parse(result).to_s
    elsif text.match?(item_tmr)
      result = text.match(item_tmr)[0]
      item_name = text.chomp(result).strip
      expiry_date = Date.tomorrow.to_s
    elsif text.match?(item_days)
      result = text.match(item_days)[0]
      days_ahead = text.match(item_days)[2]
      item_name = text.chomp(result).strip
      expiry_date = (Date.today + days_ahead).to_s
    else
      item_name = text.chomp(result)
    end

    if item_name && expiry_date
      return {item: item_name, date: expiry_date, error: 0}
    elsif item_name
      return {item: item_name, error: 0, message:'No expiry date found'}
    elsif expiry_date
      return {date: expiry_date, error: 0, message:'No grocery name found'}
    else
      return {error: 1, message:'Something went wrong.'}
    end
  end
  
end
