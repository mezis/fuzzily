require 'spec_helper'

describe Fuzzily::Migration do
  subject { Class.new(ActiveRecord::Migration).extend(described_class) }

  it 'is a proper migration' do
    subject.ancestors.should include(ActiveRecord::Migration)
  end

  it 'applies cleanly' do
    silence_stream(STDOUT) { subject.up }
  end

  it 'rolls back cleanly' do
    silence_stream(STDOUT) { subject.up ; subject.down }
  end

  it 'has a customizable table name' do
    subject.trigrams_table_name = :foobars
    silence_stream(STDOUT) { subject.up }
    expect {
      ActiveRecord::Base.connection.execute('INSERT INTO foobars (score) VALUES (1)')
    }.to_not raise_error
  end

  it 'results in a functional model' do
    silence_stream(STDOUT) { subject.up }
    model_class = Class.new(ActiveRecord::Base)
    model_class.table_name = 'trigrams'
    model_class.create(:trigram => 'abc')
    model_class.count.should == 1
  end
end
