RSpec.describe HCL::Checker do
  it 'parses floats' do
    hcl_string = 'provider "foo" {' \
                 'foo = 0.1' \
                 'bar = 1' \
                 '}'
    expect(HCL::Checker.parse(hcl_string)).to eq({
                                                   'provider' => {
                                                     'foo' => {
                                                       'foo' => 0.1,
                                                       'bar' => 1
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
    expect(HCL::Checker.valid?(hcl_string)).to eq(true)
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
    expect(HCL::Checker.valid?(hcl_string)).to eq(false)
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
    expect(ret.is_a?(Hash)).to be(true)
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
    expected_message = 'Parse error on line 1, column 196: unexpected "," (after "enable_dns_hostnames")'
    expect(ret).to eq(expected_message)
    expect(HCL::Checker.last_error).to eq(expected_message)
  end

  it 'try to parse several blocks' do
    hcl_string = 'terraform {' \
                 'required_providers {' \
                 'aws = {' \
                 'source  = "hashicorp/aws"' \
                 'version = "~> 1.0.4"' \
                 '}' \
                 '}' \
                 '}'
    ret = HCL::Checker.parse hcl_string
    expect(ret.is_a?(Hash)).to be(true)

    hcl_string = 'variable "aws_region" {}'
    ret = HCL::Checker.parse hcl_string
    expect(ret.is_a?(Hash)).to be(true)

    hcl_string = 'variable "base_cidr_block" {' \
                 'description = "A /16 CIDR range definition, such as 10.1.0.0/16, that the VPC will use"' \
                 'default = "10.1.0.0/16"' \
                 '}'
    ret = HCL::Checker.parse hcl_string
    expect(ret.is_a?(Hash)).to be(true)

    hcl_string = 'variable "availability_zones" {' \
                 'description = "A list of availability zones in which to create subnets"' \
                 'type = list(string)' \
                 '}'
    ret = HCL::Checker.parse hcl_string
    expect(ret.is_a?(Hash)).to be(true)

    hcl_string = 'provider "aws" {' \
                 'region = var.aws_region' \
                 '}'
    ret = HCL::Checker.parse hcl_string
    expect(ret.is_a?(Hash)).to be(true)

    hcl_string = 'resource "aws_vpc" "main" {' \
                 'cidr_block = var.base_cidr_block' \
                 '}'
    ret = HCL::Checker.parse hcl_string
    expect(ret.is_a?(Hash)).to be(true)
  end
end
