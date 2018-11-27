class SearchController < ApplicationController
    def identify
        voice_result = voice_params[:value]
        domain_name = voice_params[:domain]
        route_in_string = global_search_algo(voice_result,domain_name)
        
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
        params.require(:text).permit(:value, :domain)
    end

    def global_search_algo(voice_result,domain_name)
        text = voice_result.titleize
        current_user_id = current_user.id
        

        show_all = /Show\s(All\s)?(Groceries|Grocery)\s?(Groceries|Grocery)?/
        show_expired = /Show\s(All\s)?Expired\s?(Groceries|Grocery|Food)?/
        create_recipe = /(Show|Make|Create)\s(New|Recipe|Recipes)\s?(Recipe|Recipes)?/
        months = Date::MONTHNAMES.compact
        add_item_date = /Add\s((\w+\s?)+\s)(Expiring\s)(\d{1,2}(st|nd|rd|th)?(\s?(Of)?)\s(#{months.join('|')})\s\d{4})/
        add_item_date_tmr = /Add\s((\w+\s?)+\s)(Expiring\sTomorrow)/
        add_item_date_days = /Add\s((\w+\s?)+\s)(Expiring\sIn\s(\d{1,2})\sDays)/

        if text.match?(/Add/)
            if text.match?(add_item_date)
                date_item_result = text.match(add_item_date)
                item = date_item_result[1].strip
                date = Date.parse(date_item_result[4]).to_s
                route = domain_name + "users/#{current_user_id}/groceries/new?item=#{item}&expiry_date=#{date}"
            elsif text.match?(add_item_date_tmr)
                date_item_result = text.match(add_item_date_tmr)
                item = date_item_result[1].strip
                date = Date.tomorrow.to_s
                route = domain_name + "users/#{current_user_id}/groceries/new?item=#{item}&expiry_date=#{date}"    
            elsif text.match?(add_item_date_days)
                date_item_result = text.match(add_item_date_days)
                item = date_item_result[1].strip
                date = (Date.today + date_item_result[4].to_i).to_s
                route = domain_name + "users/#{current_user_id}/groceries/new?item=#{item}&expiry_date=#{date}"             
            else
                text
            end
        elsif text.match?(/Show|Make|Create/)
            if text.match?(show_all)    
                route = domain_name + "users/#{current_user_id}/groceries"  
            elsif text.match?(create_recipe)    
                route = domain_name + "users/#{current_user_id}/recipes" 
            elsif text.match?(show_expired)
                route = domain_name + "users/#{current_user_id}/expired"
            else
                text
            end
        else
            text
        end
    end
end