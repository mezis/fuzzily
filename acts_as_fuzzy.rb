module Fuzzily
  module StringExt
    def trigrams
      normalized_words.map do |word|
        (0..(word.length - 3)).map { |index| word[index,3] }
      end.flatten.uniq
    end

    private

    # Remove accents, downcase, replace spaces and word start with '*',
    # return list of normalized words
    def normalized_words
      self.split(/\s+/).map { |word|
        Iconv.iconv('ascii//translit//ignore', 'utf-8', word).first.downcase.gsub(/\W/,'')
      }.
      delete_if(&:empty?).
      map { |word|
        "**#{word}"
      }
    end
  end

  module Trigram
    # Needs fields: trigram, owner_type, owner_id, score
    # Needs index on [owner_type, trigram] and [owner_type, owner_id]

    def self.included(by)
      by.kind_of?(ActiveRecord::Base) or raise 'Not included in an ActiveRecord subclass'
      by.class_eval do
        return if class_variable_get(:@@fuzzily_trigram_model)

        belongs_to :owner, :polymorphic => true
        validates_presence_of     :owner
        validates_uniqueness_of   :trigram, :scope => [:owner_type, :owner_id]
        validates_length_of       :trigram, :is => 3
        validates_presence_of     :score

        class_variable_set(:@@fuzzily_trigram_model, true)
      end
    end

    # options:
    # - model (mandatory)
    # - field (mandatory)
    # - limit (default 10)
    def matches_for(options = {})
      options[:limit] ||= 10
      self.
        scoped(:select => 'owner_id, owner_type, SUM(score) AS score').
        scoped(:group => :owner_id).
        scoped(:order => 'score DESC', :limit => options[:limit]).
        scoped(:conditions => { :owner_type => options[:model], :field => options[:field] }).
    end
  end


  module Searchable
    # fuzzily_searchable <field> [, <field>...] [, <options>]
    def fuzzily_searchable(fields*)
      options = args.last.kind_of?(Hash) ? args.pop : {}

      fields.each do |field|
        make_field_fuzzily_searchable(field, options)
      end
    end

    private

    def make_field_fuzzily_searchable(field, options={})
      trigram_class_name = options.fetch(:class_name, 'Trigram')
      trigram_association = "trigrams_for_#{field}".to_sym
      has_many trigram_association,
        :class_name => trigram_class_name,
        :as => :owner,
        :conditions => { :field => field },
        :dependent => destroy

      define_method "find_by_fuzzy_#{field}".to_sym do |pattern, options={}|
        Trigram.matches_for(options.merge(:model => self.name, :field => field))
      end

      after_save do |record|
        next unless record.send("#{field}_changed?".to_sym)
        self.send(trigram_association).destroy_all
        self.send(field).extend(StringExt).trigrams.each do |trigram|
          self.send(trigram_association).create!(:score => 1, :trigram => trigram)
        end
      end
    end

  end
end
  # ActiveRecord::Base.extend(FuzzilySearchable)

