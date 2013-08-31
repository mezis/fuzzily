module Fuzzily
  module Model
    # Needs fields: trigram, owner_type, owner_id, score
    # Needs index on [owner_type, trigram] and [owner_type, owner_id]

    def self.included(by)
      by.ancestors.include?(ActiveRecord::Base) or raise 'Not included in an ActiveRecord subclass'
      by.extend(ClassMethods)

      by.class_eval do
        return if class_variable_defined?(:@@fuzzily_trigram_model)

        belongs_to :owner, :polymorphic => true
        validates_presence_of     :owner
        validates_uniqueness_of   :trigram, :scope => [:owner_type, :owner_id, :fuzzy_field]
        validates_length_of       :trigram, :is => 3
        validates_presence_of     :score
        validates_presence_of     :fuzzy_field

        _add_fuzzy_scopes
        class_variable_set(:@@fuzzily_trigram_model, true)
      end
    end

    module ClassMethods
      def matches_for(text)
        _matches_for_trigrams Fuzzily::String.new(text).trigrams
      end

      private

      module Rails2
        def _matches_for_trigrams(trigrams)
          self.
            scoped(:select => 'owner_id, owner_type, count(*) AS matches, MAX(score) AS score').
            scoped(:group => 'owner_id, owner_type').
            scoped(:order => 'matches DESC, score ASC').
            with_trigram(trigrams).
            map(&:owner)
        end

        def _add_fuzzy_scopes
          named_scope :for_model,  lambda { |model| { 
            :conditions => { :owner_type => model.kind_of?(Class) ? model.name : model  } 
          }}
          named_scope :for_field,  lambda { |field_name| {
            :conditions => { :fuzzy_field => field_name }
          }}
          named_scope :with_trigram, lambda { |trigrams| {
            :conditions => { :trigram => trigrams }
          }}
          named_scope :limit, lambda { |count| { :limit => count }}
        end
      end

      module Rails3
        def _matches_for_trigrams(trigrams)
          self.
            select('owner_id, owner_type, count(*) AS matches, MAX(score) AS score').
            group('owner_id, owner_type').
            order('matches DESC, score ASC').
            with_trigram(trigrams).
            map(&:owner)
        end

        def _add_fuzzy_scopes
          scope :for_model,  lambda { |model|
            where(:owner_type => model.kind_of?(Class) ? model.name : model)
          }
          scope :for_field,  lambda { |field_name| where(:fuzzy_field => field_name) }
          scope :with_trigram, lambda { |trigrams| where(:trigram => trigrams) }
        end
      end

      if ActiveRecord::VERSION::MAJOR == 2
        include Rails2
      else
        include Rails3
      end
    end
  end
end

