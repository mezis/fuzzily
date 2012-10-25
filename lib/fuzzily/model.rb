module Fuzzily
  module Model
    # Needs fields: trigram, owner_type, owner_id, score
    # Needs index on [owner_type, trigram] and [owner_type, owner_id]

    def self.included(by)
      by.ancestors.include?(ActiveRecord::Base) or raise 'Not included in an ActiveRecord subclass'
      by.class_eval do
        return if class_variable_defined?(:@@fuzzily_trigram_model)

        belongs_to :owner, :polymorphic => true
        validates_presence_of     :owner
        validates_uniqueness_of   :trigram, :scope => [:owner_type, :owner_id]
        validates_length_of       :trigram, :is => 3
        validates_presence_of     :score
        validates_presence_of     :fuzzy_field

        named_scope :for_model,  lambda { |model| { 
          :conditions => { :owner_type => model.kind_of?(Class) ? model.name : model  } 
        }}
        named_scope :for_field,  lambda { |field_name| {
          :conditions => { :fuzzy_field => field_name }
        }}
        named_scope :with_trigram, lambda { |trigrams| {
          :conditions => { :trigram => trigrams }
        }}

        class_variable_set(:@@fuzzily_trigram_model, true)
      end

      by.extend(ClassMethods)
    end

    module ClassMethods
      # options:
      # - model (mandatory)
      # - field (mandatory)
      # - limit (default 10)
      def matches_for(text, options = {})
        options[:limit] ||= 10
        self.
          scoped(:select => 'owner_id, owner_type, SUM(score) AS score').
          scoped(:group => :owner_id).
          scoped(:order => 'score DESC', :limit => options[:limit]).
          with_trigram(text.extend(String).trigrams).
          map(&:owner)
      end
    end
  end
end

