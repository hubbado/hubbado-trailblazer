require 'active_record'
require 'sqlite3'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV['DEBUG']

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define do
    create_table :users do |t|
      t.string :name, null: false
    end
  end
end

# Example model - replace with your actual models
class User < ActiveRecord::Base
  validates :name, presence: true
end
