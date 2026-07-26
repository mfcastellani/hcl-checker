RSpec.describe HCL::Checker do
  # This project does not evaluate expressions (see the "Expression
  # evaluation" scope decision in the README), so `%{ if }`/`%{ for }`
  # directives are not executed either - they are preserved verbatim as
  # part of the string's opaque content, exactly like `${...}` already is.
  # What matters here is that their presence does not corrupt detection of
  # where the surrounding string actually ends.
  context 'with if/else/endif directives' do
    it 'preserves a simple if/endif directive verbatim' do
      ret = HCL::Checker.parse('foo = "%{ if var.enabled }yes%{ endif }"')
      expect(ret).to eq({ 'foo' => '%{ if var.enabled }yes%{ endif }' })
    end

    it 'preserves an if/else/endif directive verbatim' do
      ret = HCL::Checker.parse('foo = "%{ if var.enabled }yes%{ else }no%{ endif }"')
      expect(ret).to eq({ 'foo' => '%{ if var.enabled }yes%{ else }no%{ endif }' })
    end

    it 'does not end the string early when the condition contains a quoted string literal' do
      # This was a real bug: `"` inside the directive's own condition used
      # to be indistinguishable from the enclosing string's closing quote.
      ret = HCL::Checker.parse('foo = "%{ if var.env == "prod" }yes%{ endif }"')
      expect(ret).to eq({ 'foo' => '%{ if var.env == "prod" }yes%{ endif }' })
    end

    it 'correctly resumes parsing the rest of the HCL file after the string' do
      ret = HCL::Checker.parse('foo = "%{ if a }b%{ endif }" bar = "baz"')
      expect(ret).to eq({ 'foo' => '%{ if a }b%{ endif }', 'bar' => 'baz' })
    end
  end

  context 'with for/endfor directives' do
    it 'preserves a for/endfor directive verbatim' do
      ret = HCL::Checker.parse('foo = "%{ for x in var.list }${x},%{ endfor }"')
      expect(ret).to eq({ 'foo' => '%{ for x in var.list }${x},%{ endfor }' })
    end

    it 'preserves nested for/endfor directives verbatim' do
      ret = HCL::Checker.parse('foo = "%{ for x in list }%{ for y in x.items }${y}%{ endfor }%{ endfor }"')
      expect(ret).to eq({ 'foo' => '%{ for x in list }%{ for y in x.items }${y}%{ endfor }%{ endfor }' })
    end
  end

  context 'with whitespace-strip markers (~)' do
    it 'preserves %{~ ... ~} verbatim, same as any other directive' do
      ret = HCL::Checker.parse('foo = "%{~ if var.enabled ~}yes%{~ endif ~}"')
      expect(ret).to eq({ 'foo' => '%{~ if var.enabled ~}yes%{~ endif ~}' })
    end
  end

  context 'mixed with interpolation' do
    it 'handles ${...} interpolation and a %{...} directive in the same string' do
      ret = HCL::Checker.parse('foo = "${a}%{ if b }c%{ endif }"')
      expect(ret).to eq({ 'foo' => '${a}%{ if b }c%{ endif }' })
    end
  end
end
