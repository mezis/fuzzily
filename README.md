# Fuzzily - fuzzy string matching for ActiveRecord

[![Build Status](https://travis-ci.org/mezis/fuzzily.png?branch=master)](https://travis-ci.org/mezis/fuzzily)
[![Dependency Status](https://gemnasium.com/mezis/fuzzily.png)](https://gemnasium.com/mezis/fuzzily)
[![Code Climate](https://codeclimate.com/github/mezis/fuzzily.png)](https://codeclimate.com/github/mezis/fuzzily)

> Show me photos of **Marakech** !
>
> Here aresome photos of **Marrakesh**, Morroco.
> Did you mean **Martanesh**, Albania, **Marakkanam**, India, or **Marasheshty**, Romania?

Blurrily finds misspelled, prefix, or partial needles in a haystack of
strings. It's a fast, [trigram](http://en.wikipedia.org/wiki/N-gram)-based, database-backed [fuzzy](http://en.wikipedia.org/wiki/Approximate_string_matching) string search/match engine for Rails.
Loosely inspired from an [old blog post](http://unirec.blogspot.co.uk/2007/12/live-fuzzy-search-using-n-grams-in.html).

Works with ActiveRecord 2.3, 3.0, 3.1, 3.2 on various Rubies.

If your dateset is big, if you need yet more speed, or do not use ActiveRecord,
check out [blurrily](http://github.com/mezis/blurrily), another gem (backed with a C extension)
with the same intent.  


## Installation

Add this line to your application's Gemfile:

    gem 'fuzzily'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fuzzily

## Usage

You'll need to setup 2 things:

- a trigram model (your search index) and its migration
- the model you want to search for

Create and ActiveRecord model in your app (this will be used to store a "fuzzy index" of all the models and fields you will be indexing):

    class Trigram < ActiveRecord::Base
      include Fuzzily::Model
    end

Create a migration for it:

    class AddTrigramsModel < ActiveRecord::Migration
      extend Fuzzily::Migration
    end

Instrument your model (your searchable fields do not have to be stored, they can be dynamic methods too):

    class MyStuff < ActiveRecord::Base
      # assuming my_stuffs has a 'name' attribute
      fuzzily_searchable :name
    end

Index your model (will happen automatically for new/updated records):

    MyStuff.bulk_update_fuzzy_name

Search!

    MyStuff.find_by_fuzzy_name('Some Name', :limit => 10)
    # => records



## Indexing more than one field

Just list all the field you want to index, or call `fuzzily_searchable` more than once: 

    class MyStuff < ActiveRecord::Base
      fuzzily_searchable :name_fr, :name_en
      fuzzily_searchable :name_de
    end


## Custom name for the index model

If you want or need to name your index model differently (e.g. because you already have a class called `Trigram`):

    class CustomTrigram < ActiveRecord::Base
      include Fuzzily::Model
    end

    class AddTrigramsModel < ActiveRecord::Migration
      extend Fuzzily::Migration
      trigrams_table_name = :custom_trigrams
    end

    class MyStuff < ActiveRecord::Base
      fuzzily_searchable :name, :class_name => 'CustomTrigram'
    end


## Speeding things up

For large data sets (millions of rows to index), the "compatible" storage
used by default will typically no longer be enough to keep the index small
enough.

Users have reported **major improvements** (2 order of magniture) when turning
the `owner_type` and `fuzzy_field` columns of the `trigrams` table from
`VARCHAR` (the default) into `ENUM`. This is particularly efficient with
MySQL and pgSQL.

This is not the default in the gem as ActiveRecord does not suport `ENUM`
columns in any version.


## License

MIT licence. Quite permissive if you ask me.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
