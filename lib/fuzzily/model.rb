module Fuzzily
  module Model
    # Needs fields: trigram, owner_type, owner_id, score
    # Needs index on [owner_type, trigram] and [owner_type, owner_id]

    def self.included(by)
      by.ancestors.include?(ActiveRecord::Base) or raise "Not included in an ActiveRecord subclass"
      by.extend(ClassMethods)

      by.class_eval do
        return if class_variable_defined?(:@@fuzzily_trigram_model)

        belongs_to :owner, polymorphic: true
        validates :owner, :score, :fuzzy_field, presence: true
        validates :trigram, length: { is: 3 }, uniqueness: {
          case_sensitive: true,
          scope: [:owner_type, :owner_id, :fuzzy_field],
        }

        _add_fuzzy_scopes
        class_variable_set(:@@fuzzily_trigram_model, true)
      end
    end

    module ClassMethods
      def matches_for(text)
        _matches_for_trigrams Fuzzily::String.new(text).trigrams
      end

      private

      def _matches_for_trigrams(trigrams)
        self.
          select("owner_id, owner_type, count(*) AS matches, MAX(score) AS score").
          group("owner_id, owner_type").
          order("matches DESC, score ASC").
          with_trigram(trigrams)
      end

      def _add_fuzzy_scopes
        scope :for_model, lambda { |model|
          where(owner_type: model.kind_of?(Class) ? model.name : model)
        }
        scope :for_field,  lambda { |field_name| where(fuzzy_field: field_name) }
        scope :with_trigram, lambda { |trigrams| where(trigram: trigrams) }
      end
    end
  end
end
