class WelcomeController < ApplicationController
    def index
        @user = current_user
        # byebug
        if current_user == nil
            render 'index_guest'    
        end
    end
end