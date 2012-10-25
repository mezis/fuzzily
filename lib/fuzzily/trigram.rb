require 'iconv'

module Fuzzily
  module String
    def trigrams
      normalized_words.map do |word|
        (0..(word.length - 3)).map { |index| word[index,3] }
      end.flatten.uniq
    end

    private

    # Remove accents, downcase, replace spaces and word start with '*',
    # return list of normalized words
    def normalized_words
      self.split(/\s+/).map { |word|
        Iconv.iconv('ascii//translit//ignore', 'utf-8', word).first.downcase.gsub(/\W/,'')
      }.
      delete_if(&:empty?).
      map { |word|
        "**#{word}"
      }
    end
  end
end
