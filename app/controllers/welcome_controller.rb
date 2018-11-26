class WelcomeController < ApplicationController
    def index
        @user = current_user
        
        if current_user == nil
            render 'index_guest'    
        end
    end
end