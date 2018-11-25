class SearchController < ApplicationController
    def identify
        voice_result = voice_params[:value]
        route_in_string = global_search_algo(voice_result)
        
        if route_in_string == voice_result.titleize
            @result = {value: route_in_string, error: 1}
        else
            @result = {value: route_in_string, error: 0}
        end

        respond_to do |f|
            f.json {render :json => @result}
        end
    end






    private

    def voice_params
        params.require(:text).permit(:value)
    end

    def global_search_algo(voice_result)
        text = voice_result.titleize
        current_user_id = current_user.id

        add_new = /Add\s(New|Groceries|Grocery)\s?(Groceries|Grocery)?/
        show_all = /Show\s(All|Groceries|Grocery)\s?(Groceries|Grocery)?/
        create_recipe = /(Show|Make|Create)\s(New|Recipe|Recipes)\s?(Recipe|Recipes)?/
        months = Date::MONTHNAMES.compact
        add_item_date = /Add\s((\w+\s?)+\s)(\d{1,2}(st|nd|rd|th)?(\s?(Of)?)\s(#{months.join('|')})\s\d{4})/


        if text.match?(add_new)
            route = "/users/#{current_user_id}/groceries/new"
        elsif text.match?(add_item_date)
            date_item_result = text.match(add_item_date)
            item = date_item_result[1].strip
            date = Date.parse(date_item_result[3]).to_s
            route = "users/#{current_user_id}/groceries/new?item=#{item}&expiry_date=#{date}"
        elsif text.match?(show_all)    
            route = "/users/#{current_user_id}/groceries"  
        elsif text.match?(create_recipe)    
            route = "/users/#{current_user_id}/recipies"            
        else
            text
        end

    end
end