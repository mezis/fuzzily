require 'spec_helper'

describe Fuzzily::String do
  def result(string)
    string.extend(described_class).trigrams
  end
  
  it 'splits strings into trigrams' do
    result('Paris').should == %w(**p *pa par ari ris)
  end

  it 'removes accents' do
    result('Montélimar').should == %w(**m *mo mon ont nte tel eli lim ima mar)
  end

  it 'handles multi word strings' do
    result('Le Mans').should == %w(**l *le le* e*m *ma man ans)
  end

  it 'removes symbols' do
    result('Besse-en-Chandesse').should == %w(**b *be bes ess sse se* e*e *en en* n*c *ch cha han and nde des)
  end
end