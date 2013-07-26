require "fuzzily/version"
require "fuzzily/searchable"
require "fuzzily/migration"
require "fuzzily/model"
require "active_record"

begin
  gem "rails", ">=3.0"
  require "tasks/tasks"
rescue Gem::LoadError
  # rails not available
end

ActiveRecord::Base.extend(Fuzzily::Searchable)