require 'timeout'

RSpec.describe HCL::Checker do
  context 'with an unterminated quoted string' do
    # `consume_string` used to loop calling `StringScanner#scan_until`,
    # which returns nil (without advancing) when no match is found before
    # the end of input. Nothing guarded against that, so an unterminated
    # string caused an infinite loop instead of a parse error - a real hang,
    # not just an uncaught exception.
    it 'reports the string as invalid instead of hanging' do
      Timeout.timeout(2) do
        expect(HCL::Checker.valid?('foo = "unterminated string')).to eq(false)
      end
    end

    it 'returns an error message from `parse` instead of hanging' do
      Timeout.timeout(2) do
        expect(HCL::Checker.parse('foo = "unterminated string')).to be_a(String)
      end
    end
  end

  context 'with an unterminated block comment' do
    # `consume_comment` used to silently `break` out of its loop when it
    # hit the end of input without finding a closing `*/`, treating an
    # unterminated comment as if it had been closed successfully instead of
    # reporting an error.
    it 'reports the comment as invalid instead of silently accepting it' do
      expect(HCL::Checker.valid?('foo = 1 /* unterminated comment')).to eq(false)
    end
  end

  context 'with characters the lexer does not recognize' do
    # These previously raised an uncaught HCL::Checker::Lexer::ScanError
    # instead of being reported through the normal `valid?`/`parse` API.
    %w[@ ~bar &bar |bar `x`].each do |snippet|
      hcl_string = "foo = #{snippet}"

      it "reports `#{snippet}` as invalid instead of raising" do
        expect { HCL::Checker.valid?(hcl_string) }.not_to raise_error
        expect(HCL::Checker.valid?(hcl_string)).to eq(false)
      end

      it "returns an error message from `parse` for `#{snippet}` instead of raising" do
        expect { HCL::Checker.parse(hcl_string) }.not_to raise_error
        expect(HCL::Checker.parse(hcl_string)).to be_a(String)
      end

      it "sets `last_error` after failing to lex `#{snippet}`" do
        HCL::Checker.valid?(hcl_string)
        expect(HCL::Checker.last_error).not_to be_nil
      end
    end
  end
end
