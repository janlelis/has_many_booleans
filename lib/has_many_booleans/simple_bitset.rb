#  J-_-L

# binary representation/bitset: store an array of indices in one decimal number

class Array
  # Generates an integer representing all the set bits
  def to_bri # to binary representation integer
    self.inject(0){ |ret, cur| ret + 2**cur }
  end
end

# binary representation/bitset: store an array of indices in one decimal number

class Integer
  # Generates an array consisting of the set bit indexes.
  def to_bra # to binary representation array
    ret = []
    i = 0
    while self >= x = x ? x*2 : 1
      ret << i if 0 < self[i] # ruby sugar: bit is set?
      i+=1
    end

    ret
  end

=begin other versions

  # old one
  def to_bra
    # convert the decimal integer to binary form with to_s and base 2 and then
    # check each char to add the current index to the array, if it is set
    self.to_s(2).reverse.chars.each_with_index do |ele,index|
      ret << index if ele == '1'
    end
  end

  # cool one... but uses float :/
  def to_bra
    (0..Math.log(self)/Math.log(2)).select{ |e| 0<self & 2**e }
  end

  # same again (without float)
  def to_bra
    ret = []
    i = 0
    while self >= x = x ? x*2 : 1
      ret << i if 0 < self & x
      i+=1
    end

    ret
  end

  # faster, uses 1.9
  def to_bra
    self.to_s(2).reverse.bytes.each_with_index.select{|e,_|e == 49}.map &:pop
  end

=end
end

# J-_-L

