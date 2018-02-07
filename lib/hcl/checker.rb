require 'hcl/checker/version'
require_relative 'lexer'
require_relative 'parser'

module HCL
  module Checker
    def self.valid?(value)
      ret = HCLParser.new.parse(value)
      return true if ret.is_a? Hash
      false
    rescue
      false
    end

    def self.parse(value)
      HCLParser.new.parse(value)
    rescue Racc::ParseError => e
      return e.message
    end
  end
end
