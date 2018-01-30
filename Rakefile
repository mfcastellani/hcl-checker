require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new do |c|
  options = ["--color"]
  options += ["--format", "documentation"]
  c.rspec_opts = options
end

desc "Generate HCL Lexer"
task :lexer do
  `rex  ./assets/lexer.rex -o ./lib/hcl/lexer.rb`
end

desc "Generate HCL Parser"
task :parser do
  `racc ./assets/parse.y -o ./lib/parser.rb`
end
