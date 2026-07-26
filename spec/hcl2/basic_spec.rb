RSpec.describe HCL::Checker do
  it 'parses blocks with comments and HCL2 expressions inside' do
    hcl_string = %(
      resource "aws_subnet" "az" {
        # Create one subnet for each given availability zone.
        count = length(var.availability_zones)

        # For each subnet, use one of the specified availability zones.
        availability_zone = var.availability_zones[count.index]

        # By referencing the aws_vpc.main object, Terraform knows that the subnet
        # must be created only after the VPC is created.
        vpc_id = aws_vpc.main.id

        # Built-in functions and operators can be used for simple transformations of
        # values, such as computing a subnet address. Here we create a /20 prefix for
        # each subnet, using consecutive addresses for each availability zone,
        # such as 10.1.16.0/20 .
        cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index+1)
      }
    )
    ret = HCL::Checker.parse hcl_string
    expect(ret).to eq({
                        'resource' => {
                          'aws_subnet' => {
                            'az' => {
                              'count' => 'length(var.availability_zones)',
                              'availability_zone' => 'var.availability_zones[count.index]',
                              'vpc_id' => 'aws_vpc.main.id',
                              'cidr_block' => 'cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + 1)'
                            }
                          }
                        }
                      })
  end
end
