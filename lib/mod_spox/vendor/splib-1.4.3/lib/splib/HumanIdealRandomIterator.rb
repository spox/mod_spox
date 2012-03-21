module Splib
  # IdealHumanRandomIterator - select "random" members of a population, favoring
  # those least-recently selected, to appease silly humans who hate repeats
  #
  # Abstract:
  # given a decently-sized set of items (say, 100 famous quotes), an
  # average persons's idea of N "random" entries is not actually random.
  # people don't want items to appear twice in a row, or too frequently
  # (even though true randomness means this is just as likely as any other order).
  #
  # instead, design a scheme whereby LRU items are weighted more heavily,
  # to "encourage" subsequent selections to not repeat.
  #
  # Author: Ryan "pizza_" Flynn
  # - pulled from the algodict project
  # - - http://github.com/pizza/algodict
  class IdealHumanRandomIterator
    
    def initialize(list)
      raise ArgumentError.new("Array type required") unless list.is_a?(Array)
      @items = list
    end
    
    # Given length L, generate a random number in the range [0,len-1), heavily
    # weighted towards the low end.
    def self.nexti(len)
      len += 1 if len % 2 == 1
      index = len > 2 ? rand(len/2) : 0
      return index
    end
    
    # return a psuedo-random member of items. subsequent calls should never
    # return the same item.
    def next()
      index = IdealHumanRandomIterator.nexti(@items.length)
      @items.push @items.delete_at(index)
      return @items.last
    end
  end
end