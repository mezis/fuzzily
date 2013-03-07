require 'active_support/core_ext/string/multibyte'

module Fuzzily
  module String
    def trigrams
      normalized = self.normalize
      number_of_trigrams = normalized.length - 3
      trigrams = (0..number_of_trigrams).map { |index| normalized[index,3] }.uniq
    end

    def scored_trigrams
      trigrams_ = self.trigrams
      trigrams_.map { |t| [t, trigrams_.length] }
    end

    protected

    # Remove accents, downcase, replace spaces and word start with '*',
    # return list of normalized words
    def normalize
      # Iconv.iconv('ascii//translit//ignore', 'utf-8', self).first.
      ActiveSupport::Multibyte::Chars.new(self).
        mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/,'').downcase.to_s.
        gsub(/\W/,' ').
        gsub(/\s+/,'*').
        gsub(/^/,'**')
    end
  end
end
