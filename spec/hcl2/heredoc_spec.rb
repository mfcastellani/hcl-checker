RSpec.describe HCL::Checker do
  context 'with the indented `<<-` form' do
    it 'strips the common leading whitespace from every content line' do
      hcl_string = %(
        custom_data = <<-EOF
          #!/bin/bash
          export CLOUD_ID=${var.org_id}
        EOF
      )
      ret = HCL::Checker.parse(hcl_string)
      expect(ret).to eq({ 'custom_data' => "#!/bin/bash\nexport CLOUD_ID=${var.org_id}\n" })
    end

    it 'only strips the common minimum indent, preserving relative indentation' do
      hcl_string = %(
        custom_data = <<-EOF
              line one
            line two
                line three
        EOF
      )
      ret = HCL::Checker.parse(hcl_string)
      expect(ret).to eq({ 'custom_data' => "  line one\nline two\n    line three\n" })
    end

    it 'ignores blank lines when computing the common indent' do
      hcl_string = %(
        custom_data = <<-EOF
            line one

            line two
        EOF
      )
      ret = HCL::Checker.parse(hcl_string)
      expect(ret).to eq({ 'custom_data' => "line one\n\nline two\n" })
    end

    it 'does not leak the closing marker (and its indentation) into the content' do
      hcl_string = %(
        custom_data = <<-EOF
          hello
        EOF
        foo = "bar"
      )
      ret = HCL::Checker.parse(hcl_string)
      expect(ret).to eq({ 'custom_data' => "hello\n", 'foo' => 'bar' })
    end
  end

  context 'with the plain `<<` form' do
    it 'preserves indentation verbatim (no dedent)' do
      hcl_string = %(
        policy = <<EOF
          {
            "Version": "2012-10-17"
          }
        EOF
      )
      ret = HCL::Checker.parse(hcl_string)
      expect(ret).to eq({ 'policy' => "          {\n            \"Version\": \"2012-10-17\"\n          }\n" })
    end

    it 'does not leak the closing marker into the content' do
      hcl_string = %(
        foo = <<EOF
        hello
        EOF
        bar = "baz"
      )
      ret = HCL::Checker.parse(hcl_string)
      expect(ret).to eq({ 'foo' => "        hello\n", 'bar' => 'baz' })
    end
  end

  context 'with an unterminated heredoc' do
    it 'reports an error instead of raising an uncaught exception' do
      expect { HCL::Checker.valid?("foo = <<-EOF\nbar") }.not_to raise_error
      expect(HCL::Checker.valid?("foo = <<-EOF\nbar")).to eq(false)
    end
  end
end
