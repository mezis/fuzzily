# encoding: utf-8
require 'spec_helper'

describe Fuzzily::String do
  def result(string)
    described_class.new(string).trigrams
  end
  
  it 'splits strings into trigrams' do
    result('Paris').should == %w(**p *pa par ari ris is*)
  end

  it 'removes accents' do
    result('Montélimar').should == %w(**m *mo mon ont nte tel eli lim ima mar ar*)
  end

  it 'handles multi word strings' do
    result('Le Mans').should == %w(**l *le le* e*m *ma man ans ns*)
  end

  it 'removes symbols and duplicates' do
    # The final ess, sse, se* would be dupes.
    result('Besse-en-Chandesse').should == %w(**b *be bes ess sse se* e*e *en en* n*c *ch cha han and nde des)
  end
end