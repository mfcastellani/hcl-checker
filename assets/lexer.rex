class HCL::Checker::Lexer
option
  independent

macro
  NEWLINE               \n|\r
  BLANK                 \s+
  COMMENT               \#.*|\/\/.*$
  MCOMMENTIN            \/\*
  BOOL                  true|false
  NULL                  null(?![a-zA-Z0-9_\-])
  FOR                   for(?![a-zA-Z0-9_\-])
  IN                    in(?![a-zA-Z0-9_\-])
  IF                    if(?![a-zA-Z0-9_\-])
  NUMBER                \d+
  FLOAT                 \d+(\.\d+)?[eE][-+]?\d+|\d+\.\d+
  COMMA                 \,
  IDENTIFIER            [a-zA-Z_][a-zA-Z0-9_\-]*
  EQUAL                 \=
  QUOTE                 \"
  MINUS                 \-
  PLUS                  \+
  STAR                  \*
  SLASH                 \/
  PERCENT               \%
  ANDAND                \&\&
  OROR                  \|\|
  EQEQ                  \=\=
  NEQ                   \!\=
  LE                    \<\=
  GE                    \>\=
  LT                    \<
  GT                    \>
  ARROW                 \=\>
  QUESTION              \?
  COLON                 \:
  PERIOD                \.
  BANG                  \!
  LEFTBRACE             \{
  RIGHTBRACE            \}
  LEFTBRACKET           \[
  RIGHTBRACKET          \]
  LEFTPARENTHESES       \(
  RIGHTPARENTHESES      \)
  HEREDOCUMENT          \<<\-?

rule
# [:state]      pattern                   [actions]
#-------------------------------------------------------------------------------
                {BLANK}                   # ignore pattern
                {COMMENT}                 # ignore pattern
                {NEWLINE}                 # ignore pattern
#-------------------------------------------------------------------------------
                {MCOMMENTIN}              { consume_comment(text) }
                {BOOL}                    { [:BOOL,         to_boolean(text)]}
                {NULL}                    { [:NULL,         text]}
                {FOR}                     { [:FOR,          text]}
                {IN}                      { [:IN,           text]}
                {IF}                      { [:IF,           text]}
                {FLOAT}                   { [:FLOAT,        text.to_f] }
                {NUMBER}                  { [:NUMBER,       text.to_i] }
                {QUOTE}                   { [:STRING,       consume_string(text)] }
                {HEREDOCUMENT}            { [:STRING,       consume_heredoc(text.end_with?('-'))] }
#-------------------------------------------------------------------------------
                {LEFTBRACE}               { [:LEFTBRACE,        text]}
                {RIGHTBRACE}              { [:RIGHTBRACE,       text]}
                {LEFTBRACKET}             { [:LEFTBRACKET,      text]}
                {RIGHTBRACKET}            { [:RIGHTBRACKET,     text]}
                {LEFTPARENTHESES}         { [:LEFTPARENTHESES,  text]}
                {RIGHTPARENTHESES}        { [:RIGHTPARENTHESES, text]}
#-------------------------------------------------------------------------------
                {COMMA}                   { [:COMMA,        text]}
                {IDENTIFIER}              { [:IDENTIFIER,   text]}
#-- two-character operators must come before their one-character prefixes,
#-- since this scanner uses first-match-wins (not longest-match-wins).
                {EQEQ}                    { [:EQEQ,         text]}
                {NEQ}                     { [:NEQ,          text]}
                {LE}                      { [:LE,           text]}
                {GE}                      { [:GE,           text]}
                {ARROW}                   { [:ARROW,        text]}
                {LT}                      { [:LT,           text]}
                {GT}                      { [:GT,           text]}
                {EQUAL}                   { [:EQUAL,        text]}
                {MINUS}                   { [:MINUS,        text]}
                {PLUS}                    { [:PLUS,         text]}
                {STAR}                    { [:STAR,         text]}
                {SLASH}                   { [:SLASH,        text]}
                {PERCENT}                 { [:PERCENT,      text]}
                {ANDAND}                  { [:ANDAND,       text]}
                {OROR}                    { [:OROR,         text]}
                {QUESTION}                { [:QUESTION,     text]}
                {COLON}                   { [:COLON,        text]}
                {PERIOD}                  { [:PERIOD,       text]}
                {BANG}                    { [:BANG,         text]}

inner
  attr_reader :token_positions

  def lex(input)
    scan_setup(input)
    tokens = []
    @token_positions = []

    while token = next_token
      tokens << token
      @token_positions << current_position
    end

    tokens
  end

  # Position (line, column) right after the token that was just consumed.
  # Good enough for error reporting: for the overwhelming majority of
  # tokens (identifiers, punctuation, keywords, numbers) which never span
  # multiple lines, this is exactly where the token is. It only becomes an
  # approximation (pointing at the end rather than the start) for
  # constructs that can span several lines, such as heredocs, multi-line
  # strings or block comments.
  def current_position
    consumed = @ss.string[0...@ss.pos]
    line = consumed.count("\n") + 1
    column = consumed.length - (consumed.rindex("\n") || -1)

    [line, column]
  end


  def to_boolean(input)
    input == 'true'
  end


  def consume_comment(input)
    nested = 1

    until nested.zero?
      case(text = @ss.scan_until(%r{/\*|\*/|\z}) )
      when %r{/\*\z}
        nested += 1
      when %r{\*/\z}
        nested -= 1
      else
        raise ScanError, 'unterminated block comment'
      end
    end
  end


  def consume_string(input)
    result = ''
    nested = 0

    loop do
      text = @ss.scan_until(%r{\"|\$\{|%\{|\}|\\})
      raise ScanError, 'unterminated string' if text.nil?

      case text
      when %r{\$\{\z}
        nested += 1
      when %r{%\{\z}
        nested += 1
      when %r{\}\z}
        nested -= 1 if nested.positive?
      when %r{\\\z}
        result += text.chop + decode_escape
        next
      end

      result += text.to_s

      break if nested.zero? && text =~ %r{\"\z}
    end

    result.chop
  end

  def decode_escape
    char = @ss.getch

    case char
    when 'n' then "\n"
    when 't' then "\t"
    when 'r' then "\r"
    when '"' then '"'
    when '\\' then '\\'
    when 'u'
      hex = @ss.scan(/[0-9a-fA-F]{4}/)
      hex ? [hex.to_i(16)].pack('U') : 'u'
    when 'U'
      hex = @ss.scan(/[0-9a-fA-F]{8}/)
      hex ? [hex.to_i(16)].pack('U') : 'U'
    else
      char.to_s
    end
  end

  def consume_heredoc(indented)
    marker_line = @ss.scan_until(%r{\n})
    raise ScanError, 'unterminated heredoc: missing marker' if marker_line.nil?

    marker = marker_line.strip
    closing = /^[ \t]*#{Regexp.escape(marker)}[ \t]*(?:\n|\z)/
    raw = @ss.scan_until(closing)
    raise ScanError, "unterminated heredoc: missing closing marker '#{marker}'" if raw.nil?

    content = raw.sub(closing, '')

    indented ? dedent(content) : content
  end

  # Strips the common leading whitespace shared by every non-blank line, as
  # required for the `<<-` heredoc form. Blank (or whitespace-only) lines
  # are ignored when computing how much to strip, and are left untouched.
  def dedent(text)
    lines = text.split("\n", -1)
    indents = lines.reject { |line| line.strip.empty? }.map { |line| line[/\A[ \t]*/].length }
    indent = indents.min || 0

    lines.map { |line| line.strip.empty? ? line : line[indent..] }.join("\n")
  end
end
