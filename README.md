# Fuzzily - fuzzy string matching for ActiveRecord

[![Build Status](https://travis-ci.org/martijncasteel/fuzzily.svg?branch=master)](https://travis-ci.org/martijncasteel/fuzzily)
[![Code Climate](https://codeclimate.com/github/martijncasteel/fuzzily.png)](https://codeclimate.com/github/martijncasteel/fuzzily)

> Show me photos of **Marakech** !
>
> Here aresome photos of **Marrakesh**, Morroco.
> Did you mean **Martanesh**, Albania, **Marakkanam**, India, or **Marasheshty**, Romania?

Fuzzily finds misspelled, prefix, or partial needles in a haystack of
strings. It's a fast, [trigram](http://en.wikipedia.org/wiki/N-gram)-based, database-backed [fuzzy](http://en.wikipedia.org/wiki/Approximate_string_matching) string search/match engine for Rails.
Loosely inspired from an [old blog post](http://unirec.blogspot.co.uk/2007/12/live-fuzzy-search-using-n-grams-in.html).

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

```ruby
class Trigram < ActiveRecord::Base
  include Fuzzily::Model
end
```

Create a migration for it:

```ruby
class AddTrigramsModel < ActiveRecord::Migration
  extend Fuzzily::Migration
end
```

Instrument your model:

```ruby
class Member < ActiveRecord::Base
  # assuming member has a 'name' attribute
  fuzzily_searchable :name
end
```

*Note: The `name` part in the following method calls refers to the `:name` field. Replace it to match your searchable attribute.*

Index your model (will happen automatically for new/updated records):

```ruby
Member.bulk_update_fuzzy_name
```

Search!

```ruby
Member.find_by_fuzzy_name('Some Name', :limit => 10)
# => records
```

You can force an update on a specific record with

```ruby
Member.find(123).update_fuzzy_name!
```

## Indexing more than one field

Just list all the field you want to index, or call `fuzzily_searchable` more than once:

```ruby
class Member < ActiveRecord::Base
  fuzzily_searchable :first_name, :last_name
  fuzzily_searchable :infix
end
```

## Speeding things up

For large data sets (millions of rows to index), the "compatible" storage
used by default will typically no longer be enough to keep the index small
enough.

Users have reported **major improvements** (2 order of magnitude) when turning
the `owner_type` and `fuzzy_field` columns of the `trigrams` table from
`VARCHAR` (the default) into `ENUM`. This is particularly efficient with
MySQL and pgSQL.

This is not the default in the gem as ActiveRecord does not suport `ENUM`
columns in any version.

## Primary key

When using Rails 4 with UUID's, you will need to change the `owner_id` column type to `UUID`.

```ruby
class AddTrigramsModel < ActiveRecord::Migration
  extend Fuzzily::Migration
  trigrams_owner_id_column_type = :uuid
end
```

If you set your Model primary key (id) AS `VARCHAR` instead of `INT`, you will need to change the `owner_id` column type from `INT` to `VARCHAR` in the trigrams table.

## Searching virtual attributes

Your searchable fields do not have to be stored, they can be dynamic methods
too. Just remember to add a virtual change method as well.
For instance, if you model has `first_name` and `last_name` attributes, and you
want to index a compound `name` dynamic attribute:

```ruby
class Member < ActiveRecord::Base
  fuzzily_searchable :name
  def name
    "#{first_name} #{last_name}"
  end

  def name_changed?
    first_name_changed? || last_name_changed?
  end
end
```

## Update Trigram index using `sidekiq-delay`

For larger text, it takes time to build the index. Thus it can be moved into delay task using `sidekiq` + `sidekiq-delay` or `delayed_job` gem, both of them provide the method `delay` to move the execution to background thread by adding option `async`:

```ruby
class Employee < ActiveRecord::Base
  fuzzily_searchable :name, async: true

end
```

## License

MIT licence. Quite permissive if you ask me.

Copyright (c) 2013 HouseTrip Ltd.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


Thanks to @bclennox, @fdegiuli, @nickbender, @Shanison, @rickbutton for pointing out
and/or helping on various issues.
