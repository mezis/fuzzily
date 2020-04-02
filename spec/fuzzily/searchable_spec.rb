require "spec_helper"

describe Fuzzily::Searchable do
  # Prepare ourselves a Trigram repository
  before do
    unless defined?(Trigram)
      Trigram = Class.new(ActiveRecord::Base)
      Trigram.class_eval { include Fuzzily::Model }
    end
  end

  before(:each) { prepare_trigrams_table }
  before(:each) { prepare_owners_table   }

  subject do
    Stuff ||= Class.new(ActiveRecord::Base)
    def Stuff.name ; "Stuff" ; end
    Stuff
  end

  describe ".fuzzily_searchable" do
    it "is available to all of ActiveRecord" do
      expect(subject).to respond_to(:fuzzily_searchable)
    end

    it "adds a find_by_fuzzy_<field> method" do
      subject.fuzzily_searchable :name
      expect(subject).to respond_to(:find_by_fuzzy_name)
    end

    it "is idempotent" do
      subject.fuzzily_searchable :name
      subject.fuzzily_searchable :name
      expect(subject).to respond_to(:find_by_fuzzy_name)
    end

    it "creates the trigrams_for_<field> association" do
      subject.fuzzily_searchable :name
      expect(subject.new).to respond_to(:trigrams_for_name)
    end
  end

  describe "(callbacks)" do
    before { subject.fuzzily_searchable :name }

    it "generates trigram records on creation" do
      subject.create!(name: "Paris")
      expect(subject.last.trigrams_for_name).to_not be_empty
    end

    it "generates the correct trigrams" do
      record = subject.create!(name: "FOO")
      expect(Trigram.first.trigram).to    eq "**f"
      expect(Trigram.first.owner_id).to   eq record.id
      expect(Trigram.first.owner_type).to eq "Stuff"
    end

    it "updates all trigram records on save" do
      subject.create!(name: "Paris")
      subject.first.update_attribute :name, "Rome"
      expect(Trigram.all.map(&:trigram)).to match %w(**r *ro rom ome me*)
    end

    it "deletes all trigrams on destroy" do
      subject.create!(name: "Paris").destroy
      expect(Trigram.all).to be_empty
    end
  end

  describe "#update_fuzzy_<field>!" do
    before do
      subject.fuzzily_searchable :name
    end

    it "re-creates trigrams" do
      subject.create!(name: "Paris")
      old_ids = Trigram.all.map(&:id)
      subject.last.update_fuzzy_name!
      expect(old_ids & Trigram.all.map(&:id)).to be_empty
    end

    it "ignores nil values" do
      subject.create!(name: nil)
      subject.last.update_fuzzy_name!
      expect(Trigram.all).to be_empty
    end

    if ActiveRecord::VERSION::MAJOR <= 3
      let(:fields) {[ :score, :fuzzy_field, :trigram ]}
      before { Trigram.attr_protected  fields }

      it "tolerates mass assignment security" do
        subject.create!(name: "Paris")
        subject.last.update_fuzzy_name!
      end
    end
  end

  describe ".bulk_update_fuzzy_<field>" do
    before { subject.fuzzily_searchable :name }

    it "creates all trigrams" do
      subject.create!(name: "Paris")
      Trigram.delete_all
      subject.bulk_update_fuzzy_name
      expect(Trigram.all).to_not be_empty
    end

    it "ignores nil values" do
      subject.create!(name: nil)
      Trigram.delete_all
      subject.bulk_update_fuzzy_name
      expect(Trigram.all).to be_empty
    end
  end

  context "(integrationg test)" do
    describe "#find_by_fuzzy_<field>" do
      it "returns records" do
        subject.fuzzily_searchable :name
        @paris =   subject.create!(name: "Paris")
        @palma =   subject.create!(name: "Palma de Majorca")
        @palmyre = subject.create!(name: "La Palmyre")

        expect(subject.find_by_fuzzy_name("Piris")).to_not be_empty
        expect(subject.find_by_fuzzy_name("Piris")).to match [@paris, @palma]
        expect(subject.find_by_fuzzy_name("Paradise")).to match [@paris, @palma, @palmyre]
      end

      it "favours exact matches" do
        subject.fuzzily_searchable :name
        @new_york   = subject.create!(name: "New York")
        @yorkshire  = subject.create!(name: "Yorkshire")
        @york       = subject.create!(name: "York")
        @yorkisthan = subject.create!(name: "Yorkisthan")

        expect(subject.find_by_fuzzy_name("York")).to      match [@york, @new_york, @yorkshire, @yorkisthan]
        expect(subject.find_by_fuzzy_name("Yorkshire")).to match [@yorkshire, @york, @yorkisthan, @new_york]
      end

      it "does not favour short words" do
        subject.fuzzily_searchable :name
        @lo     = subject.create!(name: "Lo")      # **l *lo lo*
        @london = subject.create!(name: "London")  # **l *lo lon ond ndo don on*
                                                      # **l *lo lon
        expect(subject.find_by_fuzzy_name("Lon")).to eq [@london, @lo]
      end

      it "honours limit option" do
        subject.fuzzily_searchable :name
        3.times { subject.create!(name: "Paris") }
        expect(subject.find_by_fuzzy_name("Paris", limit: 2).length).to eq 2
      end

      it "limits results to 10 if limit option is not given" do
        subject.fuzzily_searchable :name
        30.times { subject.create!(name: "Paris") }
        expect(subject.find_by_fuzzy_name("Paris").length).to eq 10
      end

      it "does not limit results it limit option is present and is nil" do
        subject.fuzzily_searchable :name
        30.times { subject.create!(name: "Paris") }
        expect(subject.find_by_fuzzy_name("Paris", limit: nil).length).to eq 30
      end

      it "honours offset option" do
        subject.fuzzily_searchable :name
        3.times { subject.create!(name: "Paris") }
        expect(subject.find_by_fuzzy_name("Paris", offset: 2).length).to eq 1
      end

      it "does not raise on missing objects" do
        subject.fuzzily_searchable :name
        belgium = subject.create(name: "Belgium")
        belgium.delete
        subject.find_by_fuzzy_name("Belgium")
      end

      it "finds others alongside missing" do
        subject.fuzzily_searchable :name
        belgium1, belgium2 = 2.times.map { subject.create(name: "Belgium") }
        belgium1.delete
        expect(subject.find_by_fuzzy_name("Belgium")).to eq [belgium2]
      end
    end
  end
end
