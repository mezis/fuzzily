require "spec_helper"

describe Fuzzily::Migration do
  subject { Class.new(ActiveRecord::Migration[6.0]).extend(described_class) }

  it "is a proper migration" do
    expect(subject.ancestors).to include(ActiveRecord::Migration[6.0])
  end

  it "applies cleanly" do
    ActiveRecord::Migration.suppress_messages do
      subject.up
    end
  end

  it "rolls back cleanly" do
    ActiveRecord::Migration.suppress_messages do
      subject.up ; subject.down
    end
  end

  it "has a customizable table name" do
    ActiveRecord::Migration.suppress_messages do
      subject.trigrams_table_name = :foobars
      subject.up
      expect {
        ActiveRecord::Base.connection.execute("INSERT INTO foobars (score) VALUES (1)")
      }.to_not raise_error
    end
  end

  it "results in a functional model" do
    ActiveRecord::Migration.suppress_messages do
      subject.up
      model_class = Class.new(ActiveRecord::Base)
      model_class.table_name = "trigrams"
      model_class.create(trigram: "abc")
      expect(model_class.count).to eq 1
    end
  end
end
