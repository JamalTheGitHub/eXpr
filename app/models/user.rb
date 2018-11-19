class User < ApplicationRecord
  include Clearance::User

  has_many :groceries, dependent: :destroy
end
