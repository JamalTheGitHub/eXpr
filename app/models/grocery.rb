class Grocery < ApplicationRecord
  belongs_to :user

  def expiry_countdown
    (self.expired_date - Date.today).to_i
  end

  def expired?
    if Date.today == self.expired_date || Date.today > self.expired_date
      return true
    end
  end

  def expiring_within_3days?
    time_count = (self.expired_date - Date.today).to_i
    if time_count < 3 || time_count == 3
      return true
    else
      return false 
    end

    # if time_count = (self.expired_date - Date.today).to_i = true
    #   @exps << self.ingredient      
    # end
  end

  def show_expiring_within_3days
    
  end
end
