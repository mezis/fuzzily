require "fuzzily/version"
require "fuzzily/searchable"
require "fuzzily/migration"
require "fuzzily/model"
require "active_record"

ActiveRecord::Base.send :include, Fuzzily::Searchable
