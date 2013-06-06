module Fuzzily
  module Model
    # Needs fields: trigram, owner_type, owner_id, score
    # Needs index on [owner_type, trigram] and [owner_type, owner_id]
    


    def self.included(by)
      by.ancestors.include?(ActiveRecord::Base) or raise 'Not included in an ActiveRecord subclass'

      scope_method = ActiveRecord::VERSION::MAJOR == 2 ? :named_scope : :scope

      by.class_eval do
        return if class_variable_defined?(:@@fuzzily_trigram_model)
        
        attr_accessible: :trigram, :owner_type, :score
          
        belongs_to :owner, :polymorphic => true
        validates_presence_of     :owner
        validates_uniqueness_of   :trigram, :scope => [:owner_type, :owner_id, :fuzzy_field]
        validates_length_of       :trigram, :is => 3
        validates_presence_of     :score
        validates_presence_of     :fuzzy_field

        send scope_method, :for_model,  lambda { |model| { 
          :conditions => { :owner_type => model.kind_of?(Class) ? model.name : model  } 
        }}
        send scope_method, :for_field,  lambda { |field_name| {
          :conditions => { :fuzzy_field => field_name }
        }}
        send scope_method, :with_trigram, lambda { |trigrams| {
          :conditions => { :trigram => trigrams }
        }}

        class_variable_set(:@@fuzzily_trigram_model, true)
      end

      by.extend(ClassMethods)
    end

    module ClassMethods
      def matches_for(text)
        trigrams = Fuzzily::String.new(text).trigrams
        self.
          scoped(:select => 'owner_id, owner_type, count(*) AS matches, MAX(score) AS score').
          scoped(:group => 'owner_id, owner_type').
          scoped(:order => 'matches DESC, score ASC').
          with_trigram(trigrams).
          map(&:owner)
      end
    end
  end
end

