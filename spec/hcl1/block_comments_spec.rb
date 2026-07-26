RSpec.describe HCL::Checker do
  context 'with a simple block comment' do
    it 'ignores /* ... */ content' do
      ret = HCL::Checker.parse('foo = 1 /* a simple comment */')
      expect(ret).to eq({ 'foo' => 1 })
    end

    it 'ignores a block comment that spans multiple lines' do
      hcl_string = %(
        foo = 1
        /*
         * a multi-line comment
         */
        bar = 2
      )
      ret = HCL::Checker.parse(hcl_string)
      expect(ret).to eq({ 'foo' => 1, 'bar' => 2 })
    end
  end

  context 'with a nested block comment' do
    it 'treats the whole thing as a single comment, ending only at the outermost */' do
      # Regression test: `consume_comment` used to increment its nesting
      # counter with `nested =+ 1` (assigning +1, i.e. always resetting to
      # 1) instead of `nested += 1`. That meant the *first* `*/` ended the
      # whole comment early, leaving "still outer */" as leftover source
      # text that failed to parse.
      hcl_string = "foo = 1 /* outer /* inner */ still outer */\nbar = 2"
      ret = HCL::Checker.parse(hcl_string)
      expect(ret).to eq({ 'foo' => 1, 'bar' => 2 })
    end

    it 'handles more than two levels of nesting' do
      hcl_string = "foo = 1 /* a /* b /* c */ still b */ still a */\nbar = 2"
      ret = HCL::Checker.parse(hcl_string)
      expect(ret).to eq({ 'foo' => 1, 'bar' => 2 })
    end
  end
end
