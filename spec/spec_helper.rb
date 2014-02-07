require 'fuzzily'
require 'pathname'
require 'yaml'
require 'coveralls'

Coveralls.wear!

DATABASE = Pathname.new 'test.sqlite3'

# def get_adapter
#   ENV.fetch('FUZZILY_ADAPTER', 'sqlite3')
# end

# Database connection hashes
def get_connection_hash
  case ENV.fetch('FUZZILY_ADAPTER', 'sqlite3')
  when 'postgresql'
    {
      :adapter      => 'postgresql',
      :database     => 'fuzzily_test',
      :host         => 'localhost',
      :min_messages => 'warning',
      :username     => ENV['FUZZILY_DB_USER']
    }
  when 'mysql'
    {
      :adapter  => 'mysql2',
      :database => 'fuzzily_test',
      :host     => 'localhost',
      :username => ENV['FUZZILY_DB_USER']
    }
  when 'sqlite3'
    {
      :adapter  => 'sqlite3',
      :database => DATABASE.to_s
    }
  end
end

# A test model we'll need as a source of trigrams
class Stuff < ActiveRecord::Base ; end
class StuffMigration < ActiveRecord::Migration
  def self.up
    create_table :stuffs do |t|
      t.string :name
      t.string :data
      t.boolean :flag
      t.timestamps
    end
  end

  def self.down
    drop_table :stuffs
  end
end

RSpec.configure do |config|
  config.before(:each) do
    # Connect to & cleanup test database
    ActiveRecord::Base.establish_connection(get_connection_hash)

    %w(trigrams stuffs foobars).each do |table_name|
      ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS #{table_name};"
    end

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
    DATABASE.delete if DATABASE.exist?
  end
end
