RSpec.describe HCL::Checker do
  context 'list of complex objects ' do
    it 'accepts a list with object elements' do
      hcl_string = %{
        module "foo" {
          bar = [{
            enabled = true
          },
          {
            enabled = false
          }
          ]
        }
      }

      ret = HCL::Checker.parse hcl_string
      expect(ret).to eq({
        "module"=>{
          "foo"=>{
            "bar"=>[
              {"enabled" => true},
              {"enabled" => false},
            ]
          }
        }})
    end

    it 'accepts a list with array elements' do
      hcl_string = %{
        module "foo" {
          bar = [ [ 1, 2, 3 ] ]
        }
      }

      ret = HCL::Checker.parse hcl_string
      expect(ret).to eq({"module"=>{"foo"=>{"bar"=>[[1, 2, 3]]}}})
    end
  end

  context 'with empty file' do
    hcl_string = ''
    it("should parse") { expect(HCL::Checker.valid? hcl_string).to eq(true) }
  end
end
