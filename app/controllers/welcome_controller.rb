class WelcomeController < ApplicationController
    def index
        if signed_in?
            @groceries = User.find(current_user.id).groceries
            @exps = []
            @expired = []
            @groceries.each do |grocery|
                if grocery.expiring_within_3days?
                    @exps << grocery
                end    
            end

            @groceries.each do |grocery|
                if grocery.expired?
                    @expired << grocery
                end
            end


        elsif current_user == nil
            render 'index_guest'    
        end
    end
    
end