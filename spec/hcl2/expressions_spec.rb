RSpec.describe HCL::Checker do
  context 'with conditional (ternary) expressions' do
    it 'parses a ternary expression' do
      ret = HCL::Checker.parse('foo = var.enabled ? "yes" : "no"')
      expect(ret).to eq({ 'foo' => 'var.enabled ? yes : no' })
    end
  end

  context 'with for expressions over lists' do
    it 'parses a single-variable for expression' do
      ret = HCL::Checker.parse('foo = [for x in var.list : x.id]')
      expect(ret).to eq({ 'foo' => 'for x in var.list : x.id' })
    end

    it 'parses a for expression with index and value variables' do
      ret = HCL::Checker.parse('foo = [for i, x in var.list : x.id]')
      expect(ret).to eq({ 'foo' => 'for i, x in var.list : x.id' })
    end

    it 'parses a for expression with an if filter' do
      ret = HCL::Checker.parse('foo = [for x in var.list : x.id if x.enabled]')
      expect(ret).to eq({ 'foo' => 'for x in var.list : x.id if x.enabled' })
    end
  end

  context 'with for expressions over maps (object comprehensions)' do
    it 'parses a for expression producing key => value pairs' do
      ret = HCL::Checker.parse('foo = {for k, v in var.map : k => v}')
      expect(ret).to eq({ 'foo' => 'for k, v in var.map : k => v' })
    end

    it 'parses an object for expression with an if filter' do
      ret = HCL::Checker.parse('foo = {for k, v in var.map : k => v if v.enabled}')
      expect(ret).to eq({ 'foo' => 'for k, v in var.map : k => v if v.enabled' })
    end
  end

  context 'with splat expressions' do
    it 'parses the full splat operator' do
      ret = HCL::Checker.parse('foo = var.list[*]')
      expect(ret).to eq({ 'foo' => 'var.list[*]' })
    end

    it 'parses the full splat operator followed by an attribute access' do
      ret = HCL::Checker.parse('foo = var.list[*].id')
      expect(ret).to eq({ 'foo' => 'var.list[*].id' })
    end

    it 'parses the full splat operator followed by a chain of attribute accesses' do
      ret = HCL::Checker.parse('foo = var.list[*].a.b')
      expect(ret).to eq({ 'foo' => 'var.list[*].a.b' })
    end

    it 'parses the legacy dot-splat operator' do
      ret = HCL::Checker.parse('foo = var.list.*')
      expect(ret).to eq({ 'foo' => 'var.list.*' })
    end

    it 'parses the legacy dot-splat operator followed by an attribute access' do
      ret = HCL::Checker.parse('foo = var.list.*.id')
      expect(ret).to eq({ 'foo' => 'var.list.*.id' })
    end

    it 'parses the legacy dot-splat operator followed by a chain of attribute accesses' do
      ret = HCL::Checker.parse('foo = var.list.*.a.b')
      expect(ret).to eq({ 'foo' => 'var.list.*.a.b' })
    end
  end

  context 'with chained traversal operators (indexing and attribute access)' do
    it 'parses consecutive indexing' do
      ret = HCL::Checker.parse('foo = var.list[0][1]')
      expect(ret).to eq({ 'foo' => 'var.list[0][1]' })
    end

    it 'parses indexing followed by an attribute access' do
      ret = HCL::Checker.parse('foo = var.list[0].attr')
      expect(ret).to eq({ 'foo' => 'var.list[0].attr' })
    end

    it 'parses a long chain of attribute accesses' do
      ret = HCL::Checker.parse('foo = a.b.c.d.e')
      expect(ret).to eq({ 'foo' => 'a.b.c.d.e' })
    end
  end

  context 'with list/object literals used as expressions' do
    it 'accepts a for expression whose source is an inline list literal' do
      ret = HCL::Checker.parse('foo = [for x in [1, 2, 3] : x]')
      expect(ret).to eq({ 'foo' => 'for x in [1, 2, 3] : x' })
    end

    it 'accepts a ternary with list literals on both branches' do
      ret = HCL::Checker.parse('foo = var.enabled ? [1, 2] : [3, 4]')
      expect(ret).to eq({ 'foo' => 'var.enabled ? [1, 2] : [3, 4]' })
    end

    it 'keeps a list literal argument intact instead of flattening it into the call' do
      ret = HCL::Checker.parse('foo = bar([1, 2])')
      expect(ret).to eq({ 'foo' => 'bar([1, 2])' })
    end

    it 'keeps an empty list literal argument intact' do
      ret = HCL::Checker.parse('foo = bar([])')
      expect(ret).to eq({ 'foo' => 'bar([])' })
    end

    it 'keeps a list literal argument intact alongside other arguments' do
      ret = HCL::Checker.parse('foo = bar(1, [2, 3], 4)')
      expect(ret).to eq({ 'foo' => 'bar(1, [2, 3], 4)' })
    end

    it 'accepts an object literal as a function argument' do
      ret = HCL::Checker.parse('foo = merge({a = 1}, {b = 2})')
      expect(ret).to eq({ 'foo' => 'merge({"a"=>1}, {"b"=>2})' })
    end
  end

  context 'with the null literal' do
    it 'parses a bare null as a Ruby nil, not the string "null"' do
      ret = HCL::Checker.parse('foo = null')
      expect(ret).to eq({ 'foo' => nil })
    end

    it 'parses null as a list item' do
      ret = HCL::Checker.parse('foo = [1, null, 2]')
      expect(ret).to eq({ 'foo' => [1, nil, 2] })
    end

    it 'parses null as an object value' do
      ret = HCL::Checker.parse('foo = {a = null}')
      expect(ret).to eq({ 'foo' => { 'a' => nil } })
    end

    it 'renders as the literal text "null" (not an empty string) when used as an operand inside a larger expression' do
      ret = HCL::Checker.parse('foo = var.enabled ? null : 1')
      expect(ret).to eq({ 'foo' => 'var.enabled ? null : 1' })
    end

    it 'renders as "null" when passed as a function argument' do
      ret = HCL::Checker.parse('foo = bar(1, null, 2)')
      expect(ret).to eq({ 'foo' => 'bar(1, null, 2)' })
    end
  end

  context 'with identifiers that share a prefix with a reserved word' do
    # `for`, `in`, `if` and `null` are only reserved when they appear as a
    # standalone word; otherwise they must still be readable as ordinary
    # identifiers. `null_resource` in particular is an extremely common
    # Terraform resource type.
    %w[ingress information interpolation index internal_value format
       nullable null_value annullment].each do |name|
      it "still parses `#{name}` as a plain identifier" do
        ret = HCL::Checker.parse("foo = #{name}")
        expect(ret).to eq({ 'foo' => name })
      end
    end

    it 'still parses `null_resource` as a resource type, not the null literal' do
      ret = HCL::Checker.parse('resource "null_resource" "x" {}')
      expect(ret).to eq({ 'resource' => { 'null_resource' => { 'x' => {} } } })
    end
  end
end
