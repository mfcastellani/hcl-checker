require_relative 'checker/lexer'
require_relative 'checker/parser'
require_relative 'checker/version'

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

      def parse(value, duplicate_mode = :array)
        HCLParser.new.parse(value, duplicate_mode)
      rescue Racc::ParseError => e
        @last_error = e.message

        e.message
      end
    end
  end
end
