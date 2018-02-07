require 'hcl/checker/version'
require_relative 'lexer'
require_relative 'parser'

module HCL
  module Checker
    class << self
      attr_accessor :last_error
    end

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
    rescue
      false
    end
  end
end
