require 'spec_helper'

describe Fuzzily::Searchable do
  # Prepare ourselves a Trigram repository
  class Trigram < ActiveRecord::Base
    include Fuzzily::Model
  end

  before(:each) { prepare_trigrams_table }
  before(:each) { prepare_owners_table   }

  subject do 
    Stuff.clone.class_eval do
      def self.name ; 'Stuff' ; end
      self
    end
  end

  describe '.fuzzily_searchable' do
    it 'is available to all of ActiveRecord' do
      subject.should respond_to(:fuzzily_searchable)
    end

    it 'adds a find_by_fuzzy_<field> method' do
      subject.fuzzily_searchable :name
      subject.should respond_to(:find_by_fuzzy_name)
    end

    it 'is idempotent' do
      subject.fuzzily_searchable :name
      subject.fuzzily_searchable :name
      subject.should respond_to(:find_by_fuzzy_name)
    end

    it 'creates the trigrams_for_<field> association' do
      subject.fuzzily_searchable :name
      subject.new.should respond_to(:trigrams_for_name)
    end
  end

  describe '(callbacks)' do
    it 'generates trigram records on creation' do
      subject.fuzzily_searchable :name
      subject.create(:name => 'Paris')
      subject.last.trigrams_for_name.should_not be_empty
    end

    it 'generates the correct trigrams' do
      subject.fuzzily_searchable :name
      record = subject.create(:name => 'FOO')
      Trigram.first.trigram.should    == '**f'
      Trigram.first.owner_id.should   == record.id
      Trigram.first.owner_type.should == 'Stuff'
    end

    it 'updates all trigram records on save' do
      subject.fuzzily_searchable :name
      subject.create(:name => 'Paris')
      subject.first.update_attribute :name, 'Rome'
      Trigram.all.map(&:trigram).should =~ %w(**r *ro rom ome)
    end
  end

  describe '#find_by_fuzzy_<field>' do
    it 'works'
  end

  describe '#update_fuzzy_<field>!' do
    it 'works'
  end

end