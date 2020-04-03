require "spec_helper"

describe Fuzzily::String do
  def result(string)
    described_class.new(string).trigrams
  end

  it "splits strings into trigrams" do
    expect(result("Paris")).to eq %w(**p *pa par ari ris is*)
  end

  it "removes accents" do
    expect(result("Montélimar")).to eq %w(**m *mo mon ont nte tel eli lim ima mar ar*)
  end

  it "allows numbers" do
    expect(result("GTA 5")).to eq %w(**g *gt gta ta* a*5 *5*)
  end

  it "handles multi word strings" do
    expect(result("Le Mans")).to eq %w(**l *le le* e*m *ma man ans ns*)
  end

  it "removes symbols and duplicates" do
    # The final ess, sse, se* would be dupes.
    expect(result("Besse-en-Chandesse")).to eq %w(**b *be bes ess sse se* e*e *en en* n*c *ch cha han and nde des)
  end
end
