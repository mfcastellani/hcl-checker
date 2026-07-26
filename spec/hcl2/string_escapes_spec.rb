RSpec.describe HCL::Checker do
  context 'with standard escape sequences' do
    it 'decodes \n as a newline' do
      ret = HCL::Checker.parse('foo = "a\nb"')
      expect(ret).to eq({ 'foo' => "a\nb" })
    end

    it 'decodes \t as a tab' do
      ret = HCL::Checker.parse('foo = "a\tb"')
      expect(ret).to eq({ 'foo' => "a\tb" })
    end

    it 'decodes \r as a carriage return' do
      ret = HCL::Checker.parse('foo = "a\rb"')
      expect(ret).to eq({ 'foo' => "a\rb" })
    end

    it 'decodes \" as a literal quote' do
      ret = HCL::Checker.parse('foo = "a\"b"')
      expect(ret).to eq({ 'foo' => 'a"b' })
    end

    it 'decodes \\\\ as a single backslash' do
      ret = HCL::Checker.parse('foo = "a\\\\b"')
      expect(ret).to eq({ 'foo' => 'a\\b' })
    end
  end

  context 'with unicode escape sequences' do
    it 'decodes \uNNNN (4 hex digits) to the corresponding character' do
      ret = HCL::Checker.parse('foo = "aAb"')
      expect(ret).to eq({ 'foo' => 'aAb' })
    end

    it 'decodes \UNNNNNNNN (8 hex digits) to the corresponding character' do
      ret = HCL::Checker.parse('foo = "a\U0001F600b"')
      expect(ret).to eq({ 'foo' => "a\u{1F600}b" })
    end
  end

  context 'with an unrecognized or malformed escape' do
    it 'falls back to the literal character after an unknown escape' do
      ret = HCL::Checker.parse('foo = "a\zb"')
      expect(ret).to eq({ 'foo' => 'azb' })
    end

    it 'falls back to a literal "u" when \u is not followed by 4 hex digits' do
      ret = HCL::Checker.parse('foo = "a\u12xb"')
      expect(ret).to eq({ 'foo' => 'au12xb' })
    end
  end

  context 'regression: interpolation and brace content are unaffected' do
    it 'still preserves ${...} interpolation verbatim' do
      ret = HCL::Checker.parse('foo = "${var.aws_region}"')
      expect(ret).to eq({ 'foo' => '${var.aws_region}' })
    end

    it 'still parses a plain string containing braces' do
      ret = HCL::Checker.parse('foo = "Event {Store} VPC"')
      expect(ret).to eq({ 'foo' => 'Event {Store} VPC' })
    end
  end
end
