# Hcl::Checker

**Hashicorp Configuration Language** syntax checker and parser.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hcl-checker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hcl-checker

## Usage

Load HCL string:

```ruby
hcl_string = 'provider "aws" {
    region = "${var.aws_region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

# This is a awesome comment
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags {
    Name = "Event Store VPC"
  }
}'
```

You can validate the `hcl_string` contents with `valid?` method. This will
return `true` if is a valid HCL or `false` if not.

```ruby
HCL::Checker.valid? hcl_string
# => true
```

You can parse the `hcl_string` into a `Hash` with `parse` method.

```ruby
HCL::Checker.parse(hcl_string)
# => {"provider"=>{"aws"=>{"region"=>"${var.aws_region}", "access_key"=>"${var.aws_access_key}", "secret_key"=>"${var.aws_secret_key}"}}, "resource"=>{"aws_vpc"=>{"default"=>{"cidr_block"=>"10.0.0.0/16", "enable_dns_hostnames"=>true, "tags"=>{"Name"=>"Event Store VPC"}}}}}
```

If after a `parse` you got a `String` back instead of a `Hash`, that string
is the parse error message, and it is also available afterwards via
`last_error`:

```ruby
HCL::Checker.last_error
# => "Parse error on line 7, column 18: unexpected \",\" (after \"instance_type\")"
```

## Compatibility

This gem parses full [HCL1](https://github.com/hashicorp/hcl) syntax, plus a
substantial subset of HCL2 expression syntax: arithmetic/comparison/logical
operators, ternary expressions, `for` expressions (list and object
comprehensions), splat expressions (`list[*]` and the legacy `list.*`),
chained indexing/attribute access, the `null` literal, scientific notation,
string escape sequences, `<<-` heredoc dedenting, and `%{ if }`/`%{ for }`
string template directives.

Not supported:
- The JSON variant of HCL2 (`.tf.json` files) — a fully separate parsing mode.
- Expression evaluation — this is a structural parser/checker, not an
  interpreter. `${...}` interpolations and bare expressions (function calls,
  arithmetic, `for`/ternary, etc.) are preserved as opaque text, never
  evaluated.

Known caveats:
- A quoted string used as an operand inside a larger expression loses its
  surrounding quotes in the reconstructed text (e.g. `var.env == "prod"`
  becomes the text `var.env == prod`). A string assigned directly as a value
  is unaffected (`region = "us-east-1"` stays exactly `"us-east-1"`).
- A list/object literal used as an operand inside a larger expression is
  rendered with Ruby's own `Array`/`Hash` text representation, not HCL
  syntax (e.g. `merge({a = 1}, {b = 2})` becomes the text
  `merge({"a"=>1}, {"b"=>2})`).

### Upgrading from 1.x

Version 2.0 adds the HCL2 support described above and fixes several parsing
bugs (including two that could hang or silently return wrong output). Most
HCL1 configs continue to parse identically, but a few things changed:

- **Ruby 3.3 or newer is now required** (previously `>= 2.7.0`).
- **`null` now parses as a real `nil`**, not the string `"null"`.
- **Parse error messages changed format** and now include a line and column
  number, e.g. `"Parse error on line 7, column 18: unexpected \",\" (after
  \"instance_type\")"`. Code that pattern-matches the exact old error text
  will need updating; code that only checks whether `parse` returned a
  `Hash` or a `String` (the documented, recommended pattern above) is
  unaffected.
- `for`, `in`, `if` and `null` are now reserved words when they appear as a
  standalone token, needed for HCL2's `for` expressions and the `null`
  literal. They still work as plain, unquoted attribute names and block
  labels (`for = 1`, `resource for "x" {}`), but not in every conceivable
  position — a nested block literally *labeled* `for` immediately followed
  by another bare identifier no longer parses, an extremely unusual
  construct in practice.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

> **Note:** if you run `bundle install` directly instead of `bin/setup` and
> get a `Bundler::PermissionError` trying to write to something like
> `/var/lib/gems/3.3.0/cache`, your system Ruby's gem directory is
> root-owned (common when Ruby was installed via a distro package, e.g.
> apt's `ruby3.3`). Fix it by installing into a local, writable path
> instead: `bundle config set --local path 'vendor/bundle' && bundle
> install` — this is exactly what `bin/setup` already does for you.

### Building grammar

If you change `assets/lexer.rex` or `assets/parse.y`, regenerate the lexer
and parser with:

```
$ bundle exec rake build_grammar
Building Lexer....done
Building Parser....done
```

This overwrites `lib/hcl/checker/lexer.rb` and `lib/hcl/checker/parser.rb` —
never edit those two files directly, they're marked `DO NOT MODIFY` and any
changes will be lost the next time this task runs.

## Publishing to RubyGems.org

This project uses Bundler's standard gem release workflow (`rake release`,
provided by `bundler/gem_tasks` in the `Rakefile`).

1. **Bump the version** in `lib/hcl/checker/version.rb`.
2. **Run the test suite** and make sure it's green: `bundle exec rake spec`.
3. **Commit the version bump**, e.g. `git commit -am "Bump version to X.Y.Z"`.
4. **Release**:

   ```
   $ bundle exec rake release
   ```

   This single command builds the `.gem` file from `hcl-checker.gemspec`,
   creates a git tag `vX.Y.Z`, pushes the tag and any pending commits to the
   configured remote, and pushes the built gem to
   [rubygems.org](https://rubygems.org).

If you've never pushed to rubygems.org from this machine before, `gem push`
will prompt you to sign in (or run `gem signin` beforehand to store an API
key). This gem has enough downloads that RubyGems requires multi-factor
authentication to push a new version — have your TOTP code ready, or pass it
directly with `gem push --otp <code> pkg/hcl-checker-X.Y.Z.gem` if you need
to push the built `.gem` file manually instead of via `rake release`.

To build the `.gem` file without publishing it — useful to double check its
contents first — run `bundle exec rake build`; the file is written to `pkg/`.

## Roadmap / Future work

- [ ] `HCL::Checker.last_error` is mutable class-level state (not thread-safe).
- [ ] `parse` returns a `Hash` on success and a `String` (error message) on
      failure — an ambiguous return type that forces callers to duck-type
      the result instead of, say, raising a dedicated exception class.
- [ ] No JSON variant of HCL2 (`.tf.json`) support.
- [ ] No expression evaluation — by design (see Compatibility above), but
      worth revisiting if there's ever demand for it as a separate,
      opt-in mode.

## Implementation details

Initial parser version with partial HCL 1.0 suppport was created and developed 
by [Sikula](https://github.com/sikula) 
and available at [Ruby HCL Repository](https://github.com/sikula/ruby-hcl).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/mfcastellani/hcl-checker. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere
to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
