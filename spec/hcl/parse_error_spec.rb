RSpec.describe HCL::Checker do
  context 'with a syntax error on a single-line input' do
    it 'reports the correct line and column' do
      hcl_string = 'provider "aws" {' \
                   'region = "${var.aws_region}"' \
                   '}' \
                   'resource "aws_vpc" "default" {' \
                   'enable_dns_hostnames , true' \
                   '}'
      ret = HCL::Checker.parse(hcl_string)
      expect(ret).to match(/\AParse error on line 1, column \d+: unexpected ","/)
    end
  end

  context 'with a syntax error further down a multi-line input' do
    it 'reports the line the error is actually on, not line 1' do
      hcl_string = <<~HCL
        provider "aws" {
          region = "us-east-1"
        }

        resource "aws_instance" "web" {
          ami = "ami-123"
          instance_type , "t2.micro"
        }
      HCL

      ret = HCL::Checker.parse(hcl_string)
      expect(ret).to match(/\AParse error on line 7, column \d+: unexpected ","/)
    end

    it 'includes the token that preceded the error for context' do
      hcl_string = <<~HCL
        resource "aws_vpc" "default" {
          enable_dns_hostnames , true
        }
      HCL

      ret = HCL::Checker.parse(hcl_string)
      expect(ret).to include('(after "enable_dns_hostnames")')
    end

    it 'matches between `parse` and `last_error`' do
      hcl_string = <<~HCL
        resource "aws_vpc" "default" {
          enable_dns_hostnames , true
        }
      HCL

      ret = HCL::Checker.parse(hcl_string)
      expect(HCL::Checker.last_error).to eq(ret)
    end
  end
end
