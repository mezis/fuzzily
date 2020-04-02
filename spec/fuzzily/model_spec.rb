require "spec_helper"

describe Fuzzily::Model do
  subject do
    Class.new(ActiveRecord::Base).tap do |model|
      model.table_name = :trigrams

      def model.name ; "MyModel" ; end
    end
  end

  before(:each) { prepare_trigrams_table }

  it "can be included into an ActiveRecord model" do
    subject.send(:include, described_class)
  end

  it "can be included twice" do
    subject.send(:include, described_class)
    subject.send(:include, described_class)
  end

  context "(derived model instance)" do
    before { prepare_owners_table }
    let(:model) { subject.send(:include, described_class) }

    it "belongs to an owner" do
      expect(model.new).to respond_to(:owner)
    end

    describe ".create" do
      it "can create instances" do
        model.create(owner: Stuff.create, score: 1, trigram: "abc", fuzzy_field: :name)
      end
    end

    describe ".matches_for" do
      before do
        @paris = Stuff.create(name: "Paris")
        %w(**p *pa par ari ris).each do |trigram|
          model.create(owner: @paris, score: 1, fuzzy_field: :name, trigram: trigram)
        end
      end

      it "finds matches" do
        expect(model.matches_for("Paris").map(&:owner)).to eq [@paris]
      end

      it "finds close matches" do
        expect(model.matches_for("Piriss").map(&:owner)).to eq [@paris]
      end

      it "does not confuse fields" do
        expect(model.for_field(:name).matches_for("Paris").map(&:owner)).to eq [@paris]
        expect(model.for_field(:data).matches_for("Paris").map(&:owner)).to be_empty
      end

      it "does not confuse owner types" do
        expect(model.for_model(Stuff).matches_for("Paris").map(&:owner)).to eq [@paris]
        expect(model.for_model(Object).matches_for("Paris").map(&:owner)).to be_empty
      end

      context "(with more than one entry)" do
        before do
          @palma = Stuff.create(name: "Palma")
          %w(**p *pa pal alm lma).each do |trigram|
            model.create(owner: @palma, score: 1, fuzzy_field: :name, trigram: trigram)
          end
        end

        it "returns ordered results" do
          expect(model.matches_for("Palmyre").map(&:owner)).to eq [@palma, @paris]
        end
      end
    end
  end
end
