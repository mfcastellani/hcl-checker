require 'hcl/checker/version'
require_relative 'lexer'
require_relative 'parser'

module HCL
  module Checker
    class << self
      attr_accessor :last_error

      def valid?(value)
        ret = HCLParser.new.parse(value)
        return true if ret.is_a? Hash
        false
      rescue Racc::ParseError => e
        @last_error = e.message
        false
      end

      def parse(value)
        HCLParser.new.parse(value)
      rescue Racc::ParseError => e
        @last_error = e.message
        return e.message
      end
    end
  end
end
