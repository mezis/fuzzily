require 'spec_helper'

describe Fuzzily::Searchable do
  # Prepare ourselves a Trigram repository
  before do
    silence_warnings do
      Trigram = Class.new(ActiveRecord::Base)
    end
    Trigram.class_eval { include Fuzzily::Model }
  end

  before(:each) { prepare_trigrams_table }
  before(:each) { prepare_owners_table   }

  subject do
    silence_warnings do
      Stuff = Class.new(ActiveRecord::Base)
    end
    def Stuff.name ; 'Stuff' ; end
    Stuff
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
    before { subject.fuzzily_searchable :name }

    it 'generates trigram records on creation' do
      subject.create!(:name => 'Paris')
      subject.last.trigrams_for_name.should_not be_empty
    end

    it 'generates the correct trigrams' do
      record = subject.create!(:name => 'FOO')
      Trigram.first.trigram.should    == '**f'
      Trigram.first.owner_id.should   == record.id
      Trigram.first.owner_type.should == 'Stuff'
    end

    it 'updates all trigram records on save' do
      subject.create!(:name => 'Paris')
      subject.first.update_attribute :name, 'Rome'
      Trigram.all.map(&:trigram).should =~ %w(**r *ro rom ome me*)
    end

    it 'deletes all trigrams on destroy' do
      subject.create!(:name => 'Paris').destroy
      Trigram.all.should be_empty
    end
  end

  describe '#update_fuzzy_<field>!' do
    before do
      subject.fuzzily_searchable :name
    end

    it 're-creates trigrams' do
      subject.create!(:name => 'Paris')
      old_ids = Trigram.all.map(&:id)
      subject.last.update_fuzzy_name!
      (old_ids & Trigram.all.map(&:id)).should be_empty
    end

    it 'ignores nil values' do
      subject.create!(:name => nil)
      subject.last.update_fuzzy_name!
      Trigram.all.should be_empty
    end

    if ActiveRecord::VERSION::MAJOR <= 3
      let(:fields) {[ :score, :fuzzy_field, :trigram ]}
      before { Trigram.attr_protected  fields }

      it 'tolerates mass assignment security' do
        subject.create!(:name => 'Paris')
        subject.last.update_fuzzy_name!
      end
    end
  end

  describe '.bulk_update_fuzzy_<field>' do
    before { subject.fuzzily_searchable :name }

    it 'creates all trigrams' do
      subject.create!(:name => 'Paris')
      Trigram.delete_all
      subject.bulk_update_fuzzy_name
      Trigram.all.should_not be_empty
    end

    it 'ignores nil values' do
      subject.create!(:name => nil)
      Trigram.delete_all
      subject.bulk_update_fuzzy_name
      Trigram.all.should be_empty
    end
  end

  context '(integrationg test)' do
    describe '#find_by_fuzzy_<field>' do
      it 'returns records' do
        subject.fuzzily_searchable :name
        @paris =   subject.create!(:name => 'Paris')
        @palma =   subject.create!(:name => 'Palma de Majorca')
        @palmyre = subject.create!(:name => 'La Palmyre')

        subject.find_by_fuzzy_name('Piris').should_not be_empty
        subject.find_by_fuzzy_name('Piris').should =~ [@paris, @palma]
        subject.find_by_fuzzy_name('Paradise').should =~ [@paris, @palma, @palmyre]
      end

      it 'favours exact matches' do
        subject.fuzzily_searchable :name
        @new_york   = subject.create!(:name => 'New York')
        @yorkshire  = subject.create!(:name => 'Yorkshire')
        @york       = subject.create!(:name => 'York')
        @yorkisthan = subject.create!(:name => 'Yorkisthan')

        subject.find_by_fuzzy_name('York').should      == [@york, @new_york, @yorkshire, @yorkisthan]
        subject.find_by_fuzzy_name('Yorkshire').should == [@yorkshire, @york, @yorkisthan, @new_york]
      end

      it 'does not favour short words' do
        subject.fuzzily_searchable :name
        @lo     = subject.create!(:name => 'Lo')      # **l *lo lo*
        @london = subject.create!(:name => 'London')  # **l *lo lon ond ndo don on*
                                                     # **l *lo lon
        subject.find_by_fuzzy_name('Lon').should == [@london, @lo]
      end

      it 'honours limit option' do
        subject.fuzzily_searchable :name
        3.times { subject.create!(:name => 'Paris') }
        subject.find_by_fuzzy_name('Paris', :limit => 2).length.should == 2
      end

      it 'limits results to 10 if limit option is not given' do
        subject.fuzzily_searchable :name
        30.times { subject.create!(:name => 'Paris') }
        subject.find_by_fuzzy_name('Paris').length.should == 10
      end

      it 'does not limit results it limit option is present and is nil' do
        subject.fuzzily_searchable :name
        30.times { subject.create!(:name => 'Paris') }
        subject.find_by_fuzzy_name('Paris', :limit => nil).length.should == 30
      end

      it 'honours offset option' do
        subject.fuzzily_searchable :name
        3.times { subject.create!(:name => 'Paris') }
        subject.find_by_fuzzy_name('Paris', :offset => 2).length.should == 1
      end

      it 'doesnt die on scopes' do
        subject.fuzzily_searchable :name
        subject.create!(:name => 'New York', :flag => true)
        subject.create!(:name => 'Yorkshire', :flag => false)

        expect {
         subject.where(:flag => true).find_by_fuzzy_name('York')
        }.to_not raise_error
      end

      it 'doesnt return nils' do
        subject.fuzzily_searchable :name
        subject.create!(:name => 'New York', :flag => true)
        subject.create!(:name => 'Yorkshire', :flag => false)

        results = subject.where(:flag => false).find_by_fuzzy_name('York')
        results.any?{ |r| r == nil }.should == false
      end
    end
  end

end
