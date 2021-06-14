RSpec.describe HCL::Checker do
  context 'with empty list' do
    hcl_string = %{
      bar = []
    }

    it 'accepts an empty list and should return an empty array' do
      ret = HCL::Checker.parse hcl_string
      expect(ret).to eq({ "bar" => [] })
    end
  end

  context 'with empty object' do
    hcl_string = %{
      bar = {}
    }

    it 'accepts an empty object and returns an empty hash' do
      ret = HCL::Checker.parse hcl_string
      expect(ret).to eq({ "bar" => {} })
    end
  end
end
