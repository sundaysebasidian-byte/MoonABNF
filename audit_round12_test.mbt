///|
test "additional round 12: numeric value preservation across 246 base/padding forms" {
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b0\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(0, 0, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(0, 0, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d0\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(0, 0, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(0, 0, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x0\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(0, 0, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(0, 0, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1, 1, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1, 1, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1, 1, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1, 1, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x1\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1, 1, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1, 1, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1111111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(127, 127, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001111111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(127, 127, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d127\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(127, 127, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d00000127\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(127, 127, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x7F\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(127, 127, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000007F\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(127, 127, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b11111111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(255, 255, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b0000011111111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(255, 255, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d255\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(255, 255, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d00000255\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(255, 255, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %xFF\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(255, 255, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x00000FF\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(255, 255, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b100000000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(256, 256, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b00000100000000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(256, 256, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d256\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(256, 256, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d00000256\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(256, 256, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(256, 256, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x00000100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(256, 256, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1101011111111111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(55295, 55295, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001101011111111111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(55295, 55295, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d55295\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(55295, 55295, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d0000055295\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(55295, 55295, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %xD7FF\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(55295, 55295, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x00000D7FF\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(55295, 55295, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1110000000000000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(57344, 57344, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001110000000000000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(57344, 57344, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d57344\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(57344, 57344, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d0000057344\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(57344, 57344, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %xE000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(57344, 57344, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x00000E000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(57344, 57344, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b100001111111111111111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1114111, 1114111, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b00000100001111111111111111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1114111, 1114111, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1114111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1114111, 1114111, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001114111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1114111, 1114111, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x10FFFF\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1114111, 1114111, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x0000010FFFF\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1114111, 1114111, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1111111111111111111111111111111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2147483647, 2147483647, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001111111111111111111111111111111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2147483647, 2147483647, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d2147483647\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2147483647, 2147483647, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000002147483647\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2147483647, 2147483647, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x7FFFFFFF\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2147483647, 2147483647, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000007FFFFFFF\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2147483647, 2147483647, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1001000001111111110001101001011\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1212146507, 1212146507, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001001000001111111110001101001011\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1212146507, 1212146507, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1212146507\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1212146507, 1212146507, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001212146507\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1212146507, 1212146507, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x483FE34B\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1212146507, 1212146507, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x00000483FE34B\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1212146507, 1212146507, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1011100000101001101110111000001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1544871361, 1544871361, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001011100000101001101110111000001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1544871361, 1544871361, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1544871361\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1544871361, 1544871361, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001544871361\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1544871361, 1544871361, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x5C14DDC1\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1544871361, 1544871361, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000005C14DDC1\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1544871361, 1544871361, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1101000000010011101010111001100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1745475020, 1745475020, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001101000000010011101010111001100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1745475020, 1745475020, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1745475020\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1745475020, 1745475020, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001745475020\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1745475020, 1745475020, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x6809D5CC\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1745475020, 1745475020, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000006809D5CC\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1745475020, 1745475020, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b101111111110110011111010100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(100624340, 100624340, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b00000101111111110110011111010100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(100624340, 100624340, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d100624340\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(100624340, 100624340, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d00000100624340\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(100624340, 100624340, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x5FF67D4\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(100624340, 100624340, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000005FF67D4\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(100624340, 100624340, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b10000101010100001101101111100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(279583612, 279583612, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b0000010000101010100001101101111100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(279583612, 279583612, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d279583612\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(279583612, 279583612, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d00000279583612\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(279583612, 279583612, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x10AA1B7C\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(279583612, 279583612, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x0000010AA1B7C\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(279583612, 279583612, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1011100000000001110011011000101\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1543562949, 1543562949, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001011100000000001110011011000101\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1543562949, 1543562949, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1543562949\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1543562949, 1543562949, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001543562949\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1543562949, 1543562949, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x5C00E6C5\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1543562949, 1543562949, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000005C00E6C5\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1543562949, 1543562949, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1100100011000001001101111011111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1684052959, 1684052959, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001100100011000001001101111011111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1684052959, 1684052959, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1684052959\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1684052959, 1684052959, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001684052959\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1684052959, 1684052959, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x64609BDF\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1684052959, 1684052959, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x0000064609BDF\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1684052959, 1684052959, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b110110000111010100011101110111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(907888503, 907888503, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b00000110110000111010100011101110111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(907888503, 907888503, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d907888503\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(907888503, 907888503, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d00000907888503\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(907888503, 907888503, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x361D4777\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(907888503, 907888503, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x00000361D4777\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(907888503, 907888503, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b111011100001001101010011010011\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(998560979, 998560979, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b00000111011100001001101010011010011\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(998560979, 998560979, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d998560979\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(998560979, 998560979, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d00000998560979\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(998560979, 998560979, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x3B84D4D3\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(998560979, 998560979, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000003B84D4D3\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(998560979, 998560979, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1111100100101010110000100100001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2090164513, 2090164513, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001111100100101010110000100100001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2090164513, 2090164513, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d2090164513\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2090164513, 2090164513, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000002090164513\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2090164513, 2090164513, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x7C956121\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2090164513, 2090164513, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000007C956121\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2090164513, 2090164513, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1110101011010100000011111100011\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1969883107, 1969883107, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001110101011010100000011111100011\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1969883107, 1969883107, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1969883107\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1969883107, 1969883107, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001969883107\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1969883107, 1969883107, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x756A07E3\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1969883107, 1969883107, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x00000756A07E3\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1969883107, 1969883107, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1111110111011111010000110111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(266204215, 266204215, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001111110111011111010000110111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(266204215, 266204215, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d266204215\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(266204215, 266204215, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d00000266204215\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(266204215, 266204215, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %xFDDF437\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(266204215, 266204215, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x00000FDDF437\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(266204215, 266204215, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1111110000100110000001011101100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2115175148, 2115175148, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001111110000100110000001011101100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2115175148, 2115175148, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d2115175148\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2115175148, 2115175148, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000002115175148\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2115175148, 2115175148, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x7E1302EC\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2115175148, 2115175148, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000007E1302EC\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2115175148, 2115175148, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b100100001100000111110100111100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(607157564, 607157564, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b00000100100001100000111110100111100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(607157564, 607157564, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d607157564\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(607157564, 607157564, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d00000607157564\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(607157564, 607157564, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x24307D3C\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(607157564, 607157564, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x0000024307D3C\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(607157564, 607157564, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b111111101011111000000001011100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1068466268, 1068466268, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b00000111111101011111000000001011100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1068466268, 1068466268, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1068466268\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1068466268, 1068466268, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001068466268\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1068466268, 1068466268, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x3FAF805C\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1068466268, 1068466268, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000003FAF805C\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1068466268, 1068466268, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1111001101110011010000111101001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2042208745, 2042208745, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001111001101110011010000111101001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2042208745, 2042208745, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d2042208745\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2042208745, 2042208745, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000002042208745\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2042208745, 2042208745, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x79B9A1E9\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2042208745, 2042208745, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x0000079B9A1E9\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(2042208745, 2042208745, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1101001110000010010101011101000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1774267112, 1774267112, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001101001110000010010101011101000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1774267112, 1774267112, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1774267112\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1774267112, 1774267112, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001774267112\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1774267112, 1774267112, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x69C12AE8\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1774267112, 1774267112, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x0000069C12AE8\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1774267112, 1774267112, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b11100001101111011101110101100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(473414572, 473414572, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b0000011100001101111011101110101100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(473414572, 473414572, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d473414572\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(473414572, 473414572, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d00000473414572\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(473414572, 473414572, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x1C37BBAC\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(473414572, 473414572, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000001C37BBAC\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(473414572, 473414572, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1000001111111111111010011110111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1107293431, 1107293431, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001000001111111111111010011110111\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1107293431, 1107293431, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1107293431\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1107293431, 1107293431, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001107293431\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1107293431, 1107293431, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x41FFF4F7\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1107293431, 1107293431, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x0000041FFF4F7\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1107293431, 1107293431, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1101000101101101110100100101001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1756817705, 1756817705, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001101000101101101110100100101001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1756817705, 1756817705, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1756817705\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1756817705, 1756817705, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001756817705\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1756817705, 1756817705, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x68B6E929\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1756817705, 1756817705, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x0000068B6E929\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1756817705, 1756817705, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1100111111111001111110100100011\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1744633123, 1744633123, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001100111111111001111110100100011\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1744633123, 1744633123, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1744633123\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1744633123, 1744633123, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001744633123\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1744633123, 1744633123, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x67FCFD23\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1744633123, 1744633123, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x0000067FCFD23\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1744633123, 1744633123, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1000110001101011010101110000110\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1177922438, 1177922438, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001000110001101011010101110000110\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1177922438, 1177922438, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1177922438\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1177922438, 1177922438, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001177922438\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1177922438, 1177922438, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x4635AB86\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1177922438, 1177922438, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000004635AB86\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1177922438, 1177922438, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1110110011011000001001010110000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1986794160, 1986794160, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001110110011011000001001010110000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1986794160, 1986794160, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1986794160\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1986794160, 1986794160, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001986794160\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1986794160, 1986794160, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x766C12B0\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1986794160, 1986794160, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x00000766C12B0\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1986794160, 1986794160, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1101110100011100011001101110110\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1854813046, 1854813046, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001101110100011100011001101110110\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1854813046, 1854813046, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1854813046\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1854813046, 1854813046, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001854813046\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1854813046, 1854813046, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x6E8E3376\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1854813046, 1854813046, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000006E8E3376\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1854813046, 1854813046, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b100100010101111011110101001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(76216233, 76216233, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b00000100100010101111011110101001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(76216233, 76216233, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d76216233\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(76216233, 76216233, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d0000076216233\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(76216233, 76216233, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x48AF7A9\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(76216233, 76216233, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x0000048AF7A9\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(76216233, 76216233, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b10111010101000011000001100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(48924172, 48924172, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b0000010111010101000011000001100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(48924172, 48924172, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d48924172\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(48924172, 48924172, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d0000048924172\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(48924172, 48924172, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x2EA860C\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(48924172, 48924172, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000002EA860C\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(48924172, 48924172, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b10100001001011011101011001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(42252121, 42252121, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b0000010100001001011011101011001\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(42252121, 42252121, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d42252121\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(42252121, 42252121, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d0000042252121\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(42252121, 42252121, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x284B759\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(42252121, 42252121, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x00000284B759\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(42252121, 42252121, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1101100110010100100011001101101\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1825195629, 1825195629, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001101100110010100100011001101101\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1825195629, 1825195629, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1825195629\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1825195629, 1825195629, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001825195629\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1825195629, 1825195629, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x6CCA466D\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1825195629, 1825195629, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000006CCA466D\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1825195629, 1825195629, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1100011001111010101000010101\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(208120341, 208120341, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001100011001111010101000010101\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(208120341, 208120341, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d208120341\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(208120341, 208120341, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d00000208120341\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(208120341, 208120341, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %xC67AA15\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(208120341, 208120341, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x00000C67AA15\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(208120341, 208120341, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b100111001100100111111100100100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(657620772, 657620772, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b00000100111001100100111111100100100\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(657620772, 657620772, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d657620772\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(657620772, 657620772, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d00000657620772\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(657620772, 657620772, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x27327F24\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(657620772, 657620772, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x0000027327F24\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(657620772, 657620772, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b1011011000011110010101010011000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1527720600, 1527720600, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b000001011011000011110010101010011000\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1527720600, 1527720600, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d1527720600\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1527720600, 1527720600, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d000001527720600\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1527720600, 1527720600, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x5B0F2A98\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1527720600, 1527720600, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x000005B0F2A98\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(1527720600, 1527720600, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b110100000010001000111010000110\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(872976006, 872976006, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %b00000110100000010001000111010000110\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(872976006, 872976006, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d872976006\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(872976006, 872976006, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %d00000872976006\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(872976006, 872976006, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x34088E86\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(872976006, 872976006, 4),
  )
  assert_eq(
    @moonabnf.parse_numeric(b"s = %x0000034088E86\r\n").unwrap().rules[0].expression,
    @moonabnf.Range(872976006, 872976006, 4),
  )
  assert_true(
    @moonabnf.parse_numeric(b"s = %b10000000000000000000000000000000\r\n")
    is Err(d) &&
    d.code == "number-limit",
  )
  assert_true(
    @moonabnf.parse_numeric(b"s = %d2147483648\r\n") is Err(d) &&
    d.code == "number-limit",
  )
  assert_true(
    @moonabnf.parse_numeric(b"s = %x80000000\r\n") is Err(d) &&
    d.code == "number-limit",
  )
}
