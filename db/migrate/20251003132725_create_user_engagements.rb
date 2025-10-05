class CreateUserEngagements < ActiveRecord::Migration[8.0]
  def change
    create_view :user_engagements, materialized: true
    add_index :user_engagements, :user_id, unique: true
  end
end
