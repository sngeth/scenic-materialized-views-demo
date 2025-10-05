class User < ApplicationRecord
  has_many :orders
  has_many :user_activities
  has_many :order_items, through: :orders

  validates :email, presence: true, uniqueness: true
end
