RSpec.describe HCL::Checker do
  it 'has a version number' do
    expect(HCL::Checker::VERSION).not_to be nil
  end

  it 'try to validate a valid HCL' do
    hcl_string = 'provider "aws" {' \
                 'region = "${var.aws_region}"' \
                 'access_key = "${var.aws_access_key}"' \
                 'secret_key = "${var.aws_secret_key}"' \
                 '}' \
                 'resource "aws_vpc" "default" {' \
                 'cidr_block = "10.0.0.0/16"' \
                 'enable_dns_hostnames = true' \
                 'tags {' \
                 'Name = "Event Store VPC"' \
                 '}' \
                 '}'
    expect(HCL::Checker.valid? hcl_string).to eq(true)
  end

  it 'try to validate an invalid HCL' do
    hcl_string = 'provider "aws" {' \
                 'region = "${var.aws_region}"' \
                 'access_key = "${var.aws_access_key}"' \
                 'secret_key = "${var.aws_secret_key}"' \
                 '}' \
                 'resource "aws_vpc" "default" {' \
                 'cidr_block = "10.0.0.0/16"' \
                 'enable_dns_hostnames , true' \
                 'tags {' \
                 'Name = "Event Store VPC", ' \
                 '}' \
                 '}'
    expect(HCL::Checker.valid? hcl_string).to eq(false)
  end

  it 'try to parse a valid HCL' do
    hcl_string = 'provider "aws" {' \
                 'region = "${var.aws_region}"' \
                 'access_key = "${var.aws_access_key}"' \
                 'secret_key = "${var.aws_secret_key}"' \
                 '}' \
                 'resource "aws_vpc" "default" {' \
                 'cidr_block = "10.0.0.0/16"' \
                 'enable_dns_hostnames = true' \
                 'tags {' \
                 'Name = "Event Store VPC"' \
                 '}' \
                 '}'
    ret = HCL::Checker.parse hcl_string
    expect(ret.is_a? Hash).to be(true)
  end

  it 'try to parse an invalid HCL' do
    hcl_string = 'provider "aws" {' \
                 'region = "${var.aws_region}"' \
                 'access_key = "${var.aws_access_key}"' \
                 'secret_key = "${var.aws_secret_key}"' \
                 '}' \
                 'resource "aws_vpc" "default" {' \
                 'cidr_block = "10.0.0.0/16"' \
                 'enable_dns_hostnames , true' \
                 'tags {' \
                 'Name = "Event Store VPC", ' \
                 '}' \
                 '}'
    ret = HCL::Checker.parse hcl_string
    expect(ret).to eq("Parse error at  \"enable_dns_hostnames\" , (invalid token: ,)")
  end
end
