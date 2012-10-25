require 'active_record'

module Fuzzily
  module Migration
    def self.extended(by)
      by.singleton_class.class_eval do
        def trigrams_table_name=(custom_name)
          @trigrams_table_name = custom_name
        end

        def trigrams_table_name
          @trigrams_table_name ||= :trigrams
        end

        def up
          create_table trigrams_table_name do |t|
            t.string  :trigram, :limit => 3
            t.integer :score
            t.integer :owner_id
            t.string  :owner_type
            t.string  :fuzzy_field
          end

          add_index trigrams_table_name,
            [:owner_type, :fuzzy_field, :trigram, :owner_id, :score],
            :name => :index_for_match
          add_index trigrams_table_name,
            [:owner_type, :owner_id],
            :name => :index_by_owner
        end

        def down
          drop_table trigrams_table_name
        end
      end
    end
  end
end
