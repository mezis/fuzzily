require 'fuzzily'
require 'pathname'
require 'yaml'

Database = Pathname.new 'test.sqlite3'

# A test model we'll need as a source of trigrams
class Stuff < ActiveRecord::Base ; end
class StuffMigration < ActiveRecord::Migration
  def self.up
    create_table :stuffs do |t|
      t.string :name
      t.string :data
      t.timestamps
    end
  end

  def self.down
    drop_table :stuffs
  end
end

RSpec.configure do |config|
  config.before(:each) do
    # Setup test database
    ActiveRecord::Base.establish_connection(
      :adapter  => 'sqlite3',
      :database => Database.to_s
    )

    def prepare_trigrams_table
      silence_stream(STDOUT) do
        Class.new(ActiveRecord::Migration).extend(Fuzzily::Migration).up
      end
    end

    def prepare_owners_table
      silence_stream(STDOUT) do
        StuffMigration.up
      end
    end

  end

  config.after(:each) do
    Database.delete if Database.exist?
  end
end