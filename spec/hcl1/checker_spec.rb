RSpec.describe HCL1::Checker do
  it 'parses floats' do
    hcl_string = 'provider "foo" {' \
                 'foo = 0.1' \
                 'bar = 1' \
                 '}'
    expect(HCL1::Checker.parse hcl_string).to eq({
      "provider" => {
        "foo" => {
          "foo" => 0.1,
          "bar" => 1,
        }
      }
    })
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
                 'Name = "Event {Store} VPC"' \
                 '}' \
                 '}'
    expect(HCL1::Checker.valid? hcl_string).to eq(true)
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
    expect(HCL1::Checker.valid? hcl_string).to eq(false)
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
    ret = HCL1::Checker.parse hcl_string
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
    ret = HCL1::Checker.parse hcl_string
    expect(ret).to eq("Parse error at  \"enable_dns_hostnames\" , (invalid token: ,)")
  end

  context 'valid HCL with here document' do
    hcl_string = %(
      custom_data = <<-EOF
        #!/bin/bash
        export CLOUD_ID=${var.org_id}
        export TOPOLOGY_ID=${var.topology_id}
      EOF
      provider "aws" {
        region = "${var.aws_region}"
        access_key = "${var.aws_access_key}"
        secret_key = "${var.aws_secret_key}"
      }
      resource "aws_vpc" "default" {
        cidr_block = "10.0.0.0/16"
        enable_dns_hostnames = true
        tags {
          Name = "Event Store VPC"
        }
      }
    )

    it { expect(HCL1::Checker.valid? hcl_string).to eq(true) }
  end

  context 'valid HCL with here document without hyphen' do
    hcl_string = %(
      resource "aws_iam_policy" "policy" {
        name        = "test_policy"
        path        = "/"
        description = "My test policy"

        policy = <<EOF
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Action": [
              "ec2:Describe*"
            ],
            "Effect": "Allow",
            "Resource": "*"
          }
        ]
      }
      EOF
      }
    )

    it { expect(HCL1::Checker.valid? hcl_string).to eq(true) }
  end

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

      ret = HCL1::Checker.parse hcl_string
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

      ret = HCL1::Checker.parse hcl_string
      expect(ret).to eq({"module"=>{"foo"=>{"bar"=>[[1, 2, 3]]}}})
    end
  end

  context 'with empty file' do
    hcl_string = ''
    it("should parse") { expect(HCL1::Checker.valid? hcl_string).to eq(true) }
  end

  context 'with spurious commas' do
    hcl_string = %(
      resource "aws_security_group" "allow_tls" {
        name        = "allow_tls"
        description = "Allow TLS inbound traffic"
        vpc_id      = "${aws_vpc.main.id}",

        ingress {
          from_port   = 443
          to_port     = 443
          protocol    = "-1"
          cidr_blocks = ["192.168.0.1"],
        },
      }
    )
    it("should parse") { expect(HCL1::Checker.valid? hcl_string).to eq(true) }
  end

end
