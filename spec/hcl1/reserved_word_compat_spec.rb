RSpec.describe HCL::Checker do
  # `for`, `in`, `if` and `null` became reserved words when HCL2 support was
  # added (needed for `for` expressions, `if` filters and the `null`
  # literal). Since HCL1 configs are free to use these exact words as plain,
  # unquoted attribute names or block labels, this spec locks in that they
  # still work in those positions, to protect existing HCL1 users upgrading
  # from 1.x.
  context 'as a bare (unquoted) top-level attribute name' do
    it 'still parses `for` as an attribute name' do
      expect(HCL::Checker.parse('for = 5')).to eq({ 'for' => 5 })
    end

    it 'still parses `in` as an attribute name' do
      expect(HCL::Checker.parse('in = 5')).to eq({ 'in' => 5 })
    end

    it 'still parses `if` as an attribute name' do
      expect(HCL::Checker.parse('if = 5')).to eq({ 'if' => 5 })
    end

    it 'still parses `null` as an attribute name' do
      expect(HCL::Checker.parse('null = 5')).to eq({ 'null' => 5 })
    end
  end

  context 'as a bare (unquoted) block label' do
    it 'still parses `for` as a block type/label' do
      expect(HCL::Checker.parse('resource for "x" {}')).to eq({ 'resource' => { 'for' => { 'x' => {} } } })
    end
  end

  context 'as a bare (unquoted) attribute name nested inside a block' do
    it 'still parses `for` as a nested attribute name' do
      ret = HCL::Checker.parse('resource "x" "y" { for = 5 }')
      expect(ret).to eq({ 'resource' => { 'x' => { 'y' => { 'for' => 5 } } } })
    end

    it 'still parses `null` as a nested attribute name' do
      ret = HCL::Checker.parse('resource "x" "y" { null = 5 }')
      expect(ret).to eq({ 'resource' => { 'x' => { 'y' => { 'null' => 5 } } } })
    end
  end

  context 'regression: real for/null HCL2 features still take priority when unambiguous' do
    it 'still parses a for expression over a list' do
      ret = HCL::Checker.parse('foo = [for x in list : x]')
      expect(ret).to eq({ 'foo' => 'for x in list : x' })
    end

    it 'still parses a for expression over a map' do
      ret = HCL::Checker.parse('foo = {for k, v in m : k => v}')
      expect(ret).to eq({ 'foo' => 'for k, v in m : k => v' })
    end

    it 'still parses the null literal as a real nil' do
      expect(HCL::Checker.parse('foo = null')).to eq({ 'foo' => nil })
    end
  end
end
