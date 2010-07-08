require File.dirname(__FILE__) + '/test_helper.rb'

class SimpleBitsetTest < ActiveSupport::TestCase
  test 'to_bra' do
    assert_equal 0.to_bra, []
    assert_equal 1.to_bra, [0]
    assert_equal 2.to_bra, [1]
    assert_equal 3.to_bra, [0,1]
    assert_equal 4.to_bra, [2]
    assert_equal 999999999999999999.to_bra, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 21, 22, 24, 25, 26, 29, 31, 32, 33, 36, 37, 39, 41, 42, 44, 45, 47, 53, 54, 55, 56, 58, 59]
  end

  test 'to_bri' do
    assert_equal 0, [].to_bri
    assert_equal 1, [0].to_bri
    assert_equal 2, [1].to_bri
    assert_equal 3, [0,1].to_bri
    assert_equal 4, [2].to_bri
    assert_equal 999999999999999999, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 21, 22, 24, 25, 26, 29, 31, 32, 33, 36, 37, 39, 41, 42, 44, 45, 47, 53, 54, 55, 56, 58, 59].to_bri
  end
end

