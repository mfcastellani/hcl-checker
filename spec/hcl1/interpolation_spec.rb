RSpec.describe HCL::Checker do
    context 'with interpolation only expression list' do
      hcl_string = %(
        provider "foo" {
          hoge = [var.fuga.id]
        }
      )
      it("should valid") { expect(HCL::Checker.valid? hcl_string).to eq(true) }
      it("should parse") { expect(HCL::Checker.parse hcl_string).to eq({
        "provider" => {
          "foo" => {
            "hoge" => ["var.fuga.id"]
          }
        }
      }) }
    end
  end