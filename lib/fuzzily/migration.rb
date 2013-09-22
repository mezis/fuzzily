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

        def trigrams_owner_id_column_type=(custom_type)
          @trigrams_owner_id_column_type = custom_type
        end

        def trigrams_owner_id_column_type
          @trigrams_owner_id_column_type ||= :integer
        end

        def up
          create_table trigrams_table_name do |t|
            t.string  :trigram, :limit => 3
            t.integer :score,   :limit => 2
            t.send trigrams_owner_id_column_type, :owner_id
            t.string  :owner_type
            t.string  :fuzzy_field
          end

          # owner_id goes first as we'll GROUP BY that
          add_index trigrams_table_name,
            [:owner_id, :owner_type, :fuzzy_field, :trigram, :score],
            :name => :index_for_match
          add_index trigrams_table_name,
            [:owner_id, :owner_type],
            :name => :index_by_owner
        end

        def down
          drop_table trigrams_table_name
        end
      end
    end
  end
end
