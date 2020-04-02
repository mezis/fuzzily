require "active_support/core_ext/string/multibyte"
require "delegate"
module Fuzzily
  class String < SimpleDelegator

    def trigrams
      return [] if __getobj__.nil?
      normalized = self.normalize
      number_of_trigrams = normalized.length - 3
      trigrams = (0..number_of_trigrams).map { |index| normalized[index, 3] }.uniq
    end

    def scored_trigrams
      trigrams.map { |t| [t, self.length] }
    end

    protected

    # Remove accents, downcase, replace spaces and word start with "*",
    # return list of normalized words
    def normalize
      ActiveSupport::Multibyte::Chars.new(self.to_s)
        .mb_chars.unicode_normalize(:nfkd).to_s.downcase
        .gsub(/[^\x00-\x7F]/, "")
        .gsub(/[^a-z]/, " ")
        .gsub(/\s+/, "*")
        .gsub(/^/, "**")
        .gsub(/$/, "*")
    end
  end
end
