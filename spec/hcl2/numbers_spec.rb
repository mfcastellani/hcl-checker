RSpec.describe HCL::Checker do
  context 'with scientific notation' do
    it 'parses a plain exponent as a Float' do
      ret = HCL::Checker.parse('foo = 1e10')
      expect(ret).to eq({ 'foo' => 1e10 })
    end

    it 'parses an uppercase exponent marker' do
      ret = HCL::Checker.parse('foo = 1E10')
      expect(ret).to eq({ 'foo' => 1e10 })
    end

    it 'parses an explicit positive exponent sign' do
      ret = HCL::Checker.parse('foo = 1e+10')
      expect(ret).to eq({ 'foo' => 1e10 })
    end

    it 'parses a negative exponent' do
      ret = HCL::Checker.parse('foo = 1E-5')
      expect(ret).to eq({ 'foo' => 1e-5 })
    end

    it 'parses a decimal mantissa with an exponent' do
      ret = HCL::Checker.parse('foo = 1.5e10')
      expect(ret).to eq({ 'foo' => 1.5e10 })
    end

    it 'parses a negative number in scientific notation' do
      ret = HCL::Checker.parse('foo = -1e10')
      expect(ret).to eq({ 'foo' => -1e10 })
    end

    it 'parses scientific notation as list items' do
      ret = HCL::Checker.parse('foo = [1e10, 2e-5]')
      expect(ret).to eq({ 'foo' => [1e10, 2e-5] })
    end

    it 'parses scientific notation as a function argument' do
      ret = HCL::Checker.parse('foo = bar(1e10)')
      expect(ret).to eq({ 'foo' => 'bar(10000000000.0)' })
    end

    it 'does not break plain decimal numbers' do
      ret = HCL::Checker.parse('foo = 0.1')
      expect(ret).to eq({ 'foo' => 0.1 })
    end
  end

  context 'with large numbers' do
    it 'parses an arbitrarily large plain integer without overflow, via Ruby\'s native bignum support' do
      ret = HCL::Checker.parse('foo = 99999999999999999999999999999')
      expect(ret).to eq({ 'foo' => 99_999_999_999_999_999_999_999_999_999 })
    end

    it 'is limited by IEEE754 double precision for numbers using scientific notation' do
      # Unlike plain integers, exponent-notation numbers are parsed with
      # Float#to_f, which follows normal double-precision overflow rules.
      ret = HCL::Checker.parse('foo = 1e400')
      expect(ret).to eq({ 'foo' => Float::INFINITY })
    end
  end
end
