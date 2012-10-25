# Fuzzily

A fast, trigram-based, database-backed fuzzy string search/match engine for Rails.

## Installation

Add this line to your application's Gemfile:

    gem 'fuzzily'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fuzzily

## Usage

You'll need to setup 3 things:

- a trigram model (your search index)
- its migration
- the model you want to search for

Create and ActiveRecord model in your app:

    class Trigram < ActiveRecord::Base
      include Fuzzily::Model
    end

Create a migration file:

    class AddTrigramsModel < ActiveRecord::Migration
      extend Fuzzily::Migration

      # if you named your trigram model anything but 'Trigram', e.g. 'CustomTrigram'
      # trigrams_table_name = :custom_trigrams
    end

Instrument your model (your searchable fields do not have to be stored, they can be dynamic methods too):

    class MyStuff < ActiveRecord::Base
      # assuming my_stuffs has a 'name' attribute
      fuzzily_searchable :name
    end

Index your model (will happen automatically for new/updated records):

    MyStuff.find_each do |record|
      record.update_fuzzy_name!
    end

Search!

    MyStuff.find_by_fuzzy_name('Some Name', :limit => 10)
    # => records


## License

MIT licence. Quite permissive if you ask me.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
