RSpec.describe HCL::Checker do
  context 'with arithmetic operators' do
    hcl_string = %(
      resource "aws_instance" "foo" {
        sum        = 1 + 2
        difference = 5 - 2
        product    = 2 * 3
        quotient   = 10 / 2
        remainder  = 10 % 3
      }
    )

    it 'parses arithmetic expressions' do
      ret = HCL::Checker.parse hcl_string
      expect(ret).to eq({
                          'resource' => {
                            'aws_instance' => {
                              'foo' => {
                                'sum' => '1 + 2',
                                'difference' => '5 - 2',
                                'product' => '2 * 3',
                                'quotient' => '10 / 2',
                                'remainder' => '10 % 3'
                              }
                            }
                          }
                        })
    end
  end

  context 'with comparison and logical operators' do
    hcl_string = %(
      resource "aws_instance" "foo" {
        equal      = var.a == var.b
        not_equal  = var.a != var.b
        less       = var.a < var.b
        greater    = var.a > var.b
        less_eq    = var.a <= var.b
        greater_eq = var.a >= var.b
        both       = var.a && var.b
        either     = var.a || var.b
        negation   = !var.a
      }
    )

    it 'parses comparison and logical expressions' do
      ret = HCL::Checker.parse hcl_string
      expect(ret).to eq({
                          'resource' => {
                            'aws_instance' => {
                              'foo' => {
                                'equal' => 'var.a == var.b',
                                'not_equal' => 'var.a != var.b',
                                'less' => 'var.a < var.b',
                                'greater' => 'var.a > var.b',
                                'less_eq' => 'var.a <= var.b',
                                'greater_eq' => 'var.a >= var.b',
                                'both' => 'var.a && var.b',
                                'either' => 'var.a || var.b',
                                'negation' => '!var.a'
                              }
                            }
                          }
                        })
    end
  end

  context 'with unary minus and negative numbers' do
    it 'parses a negative number literal as a Numeric' do
      expect(HCL::Checker.parse('foo = -5')).to eq({ 'foo' => -5 })
    end

    it 'parses a negative float literal as a Numeric' do
      expect(HCL::Checker.parse('foo = -5.5')).to eq({ 'foo' => -5.5 })
    end

    it 'parses unary minus applied to an identifier' do
      expect(HCL::Checker.parse('foo = -var.x')).to eq({ 'foo' => '-var.x' })
    end

    it 'treats a hyphen with no surrounding whitespace as part of the identifier' do
      # Matches the HCL2 spec: `-` only reads as subtraction when set off by
      # whitespace, otherwise it is just another identifier character.
      expect(HCL::Checker.parse('foo = var.x-1')).to eq({ 'foo' => 'var.x-1' })
    end

    it 'parses binary minus when set off by whitespace' do
      expect(HCL::Checker.parse('foo = var.x - 1')).to eq({ 'foo' => 'var.x - 1' })
    end
  end

  context 'with parenthesized expressions' do
    it 'respects explicit grouping' do
      expect(HCL::Checker.parse('foo = (1 + 2) * 3')).to eq({ 'foo' => '(1 + 2) * 3' })
    end
  end

  context 'with operators and function calls inside lists' do
    it 'accepts booleans, negative numbers and expressions as list items' do
      ret = HCL::Checker.parse('foo = [1, -2, true, false, var.x, 1+1]')
      expect(ret).to eq({ 'foo' => [1, -2, true, false, 'var.x', '1 + 1'] })
    end
  end
end
