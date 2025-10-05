class CreateUserActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :user_activities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :activity_type
      t.jsonb :metadata
      t.datetime :occurred_at

      t.timestamps
    end

    add_index :user_activities, :activity_type
    add_index :user_activities, :occurred_at
    add_index :user_activities, [:user_id, :occurred_at]
  end
end
