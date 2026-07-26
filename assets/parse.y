class HCL::Checker::Parser
token BOOL
      NULL
      FLOAT
      NUMBER
      COMMA
      COMMAEND
      IDENTIFIER
      EQUAL
      STRING
      MINUS
      PLUS
      STAR
      SLASH
      PERCENT
      ANDAND
      OROR
      EQEQ
      NEQ
      LT
      GT
      LE
      GE
      BANG
      QUESTION
      COLON
      ARROW
      FOR
      IN
      IF
      LEFTBRACE
      RIGHTBRACE
      LEFTBRACKET
      RIGHTBRACKET
      LEFTPARENTHESES
      RIGHTPARENTHESES
      PERIOD
      EPLUS
      EMINUS

prechigh
  nonassoc UMINUS
  right    BANG
  left     STAR SLASH PERCENT
  left     PLUS MINUS
  nonassoc LT GT LE GE
  nonassoc EQEQ NEQ
  left     ANDAND
  left     OROR
  right    QUESTION COLON
preclow

rule
  target: top { @result = flatten_objectlist(val[0])}

  top:
      { result = val[0] }
  |  objectlist
  ;

  objectlist:
     objectitem COMMA
       { result = [val[0]] }
  |  objectitem
       { result = [val[0]] }
  |  objectlist objectitem COMMA
       { result = val[0] << val[1]  }
  |  objectlist objectitem
       { result = val[0] << val[1]  }
  ;

  object:
     LEFTBRACE objectlist RIGHTBRACE
       { result = flatten_objectlist(val[1]) }
  |  LEFTBRACE RIGHTBRACE
       { return {} }
  |  LEFTBRACE forobjectexpr RIGHTBRACE
       { result = val[1] }
  ;

  forobjectexpr:
     FOR foriter COLON expr ARROW expr
       { result = "for #{val[1]} : #{render(val[3])} => #{render(val[5])}" }
  |  FOR foriter COLON expr ARROW expr IF expr
       { result = "for #{val[1]} : #{render(val[3])} => #{render(val[5])} if #{render(val[7])}" }
  ;

  objectkey:
     IDENTIFIER
       { result = val[0] }
  |  STRING
       { result = val[0] }
  |  FOR
       { result = val[0] }
  |  IN
       { result = val[0] }
  |  IF
       { result = val[0] }
  |  NULL
       { result = val[0] }
  ;

  objectitem:
     objectkey EQUAL expr
       { result = val[0], val[2] }
  |  block
       { result = val[0] }
  ;

  expr:
     primary
       { result = val[0] }
  |  expr PLUS expr
       { result = "#{render(val[0])} + #{render(val[2])}" }
  |  expr MINUS expr
       { result = "#{render(val[0])} - #{render(val[2])}" }
  |  expr STAR expr
       { result = "#{render(val[0])} * #{render(val[2])}" }
  |  expr SLASH expr
       { result = "#{render(val[0])} / #{render(val[2])}" }
  |  expr PERCENT expr
       { result = "#{render(val[0])} % #{render(val[2])}" }
  |  expr ANDAND expr
       { result = "#{render(val[0])} && #{render(val[2])}" }
  |  expr OROR expr
       { result = "#{render(val[0])} || #{render(val[2])}" }
  |  expr EQEQ expr
       { result = "#{render(val[0])} == #{render(val[2])}" }
  |  expr NEQ expr
       { result = "#{render(val[0])} != #{render(val[2])}" }
  |  expr LT expr
       { result = "#{render(val[0])} < #{render(val[2])}" }
  |  expr GT expr
       { result = "#{render(val[0])} > #{render(val[2])}" }
  |  expr LE expr
       { result = "#{render(val[0])} <= #{render(val[2])}" }
  |  expr GE expr
       { result = "#{render(val[0])} >= #{render(val[2])}" }
  |  expr QUESTION expr COLON expr
       { result = "#{render(val[0])} ? #{render(val[2])} : #{render(val[4])}" }
  |  BANG expr
       { result = "!#{render(val[1])}" }
  |  MINUS expr =UMINUS
       { result = negate(val[1]) }
  ;

  primary:
     traversal
       { result = val[0] }
  |  number
       { result = val[0] }
  |  BOOL
       { result = val[0] }
  |  NULL
       { result = nil }
  |  STRING
       { result = val[0] }
  |  list
       { result = val[0] }
  |  object
       { result = val[0] }
  |  LEFTPARENTHESES expr RIGHTPARENTHESES
       { result = "(#{render(val[1])})" }
  ;

  traversal:
     IDENTIFIER
       { result = val[0] }
  |  traversal PERIOD IDENTIFIER
       { result = "#{val[0]}.#{val[2]}" }
  |  traversal PERIOD STAR
       { result = "#{val[0]}.*" }
  |  traversal LEFTBRACKET expr RIGHTBRACKET
       { result = "#{val[0]}[#{render(val[2])}]" }
  |  traversal LEFTBRACKET STAR RIGHTBRACKET
       { result = "#{val[0]}[*]" }
  |  traversal LEFTPARENTHESES RIGHTPARENTHESES
       { result = "#{val[0]}()" }
  |  traversal LEFTPARENTHESES arglist RIGHTPARENTHESES
       { result = "#{val[0]}(#{val[2].map { |a| render(a) }.join(', ')})" }
  ;

  arglist:
     expr
       { result = [val[0]] }
  |  arglist COMMA expr
       { result = val[0] << val[2] }
  ;

  block:
     block_id object
       { result = val[0], val[1] }
  |  block_id block
       { result = val[0], {val[1][0] => val[1][1]} }
  ;

  block_id:
     IDENTIFIER
       { result = val[0] }
  |  STRING
       { result = val[0] }
  |  FOR
       { result = val[0] }
  |  IN
       { result = val[0] }
  |  IF
       { result = val[0] }
  |  NULL
       { result = val[0] }
  ;

  list:
     LEFTBRACKET listitems RIGHTBRACKET
       { result = val[1] }
  |  LEFTBRACKET RIGHTBRACKET
       { return [] }
  |  LEFTBRACKET forlistexpr RIGHTBRACKET
       { result = val[1] }
  ;

  forlistexpr:
     FOR foriter COLON expr
       { result = "for #{val[1]} : #{render(val[3])}" }
  |  FOR foriter COLON expr IF expr
       { result = "for #{val[1]} : #{render(val[3])} if #{render(val[5])}" }
  ;

  foriter:
     IDENTIFIER IN expr
       { result = "#{val[0]} in #{render(val[2])}" }
  |  IDENTIFIER COMMA IDENTIFIER IN expr
       { result = "#{val[0]}, #{val[2]} in #{render(val[4])}" }
  ;

  listitems:
     listitem
       { result = [val[0]] }
  |  listitems COMMA listitem
       { result = val[0] << val[2] }
  |  listitems COMMA
       { result = val[0] }
  ;

  listitem:
     expr
       { result = val[0] }
  ;

  number:
     NUMBER
       { result = val[0] }
  |  FLOAT
       { result = val[0] }
  ;


end

---- header
require_relative 'lexer'

---- inner
  #//
  #//       HCL is unclear on what one should do when duplicate
  #//       keys are encountered.
  #//
  #//       from decoder.go: if we're at the root or we're directly within
  #//                        a list, decode to hashes, otherwise lists
  #//
  #//       from object.go:  there is a flattened list structure
  #//
  #//       if @duplicate_mode is set:
  #//         - :array then duplicates will be appended to an array
  #//         - :merge then duplicates will be deep merged into a hash
  #//
  def flatten_objectlist(list)
    (list || {}).each_with_object({}) do |a, h|
      if h.keys.include?(a.first)
        case @duplicate_mode
        when :array
          if h[a.first].is_a?(Array)
            h[a.first].push(a.last)
          else
            h[a.first] = [ h[a.first], a.last ]
          end
        when :merge
          deep_merge(h[a.first] || {}, a.last)
        else raise ArgumentError
        end
      else
        h[a.first] = a.last
      end
    end
  end


  def on_error(error_token_id, error_value, value_stack)
    line, column = @current_position
    message = "Parse error on line #{line}, column #{column}: unexpected #{error_value.inspect}"
    message += " (after #{value_stack.last.inspect})" unless value_stack.empty?

    raise Racc::ParseError, message
  end


  def parse(input, duplicate_mode = :array)
    @duplicate_mode = duplicate_mode

    lexer = HCL::Checker::Lexer.new
    @lexer = lexer.lex(input)
    @lexer_positions = lexer.token_positions

    do_parse

    @result
  end


  def next_token
    @current_position = @lexer_positions.shift
    @lexer.shift
  end

  def negate(value)
    value.is_a?(Numeric) ? -value : "-#{render(value)}"
  end

  def render(value)
    value.nil? ? 'null' : value.to_s
  end

  def deep_merge(hash1, hash2)
    hash2.keys.each do |key|
      value1 = hash1[key]
      value2 = hash2[key]

      if value1.is_a?(Hash) && value2.is_a?(Hash)
        hash1[key] = deep_merge(value1, value2)
      else
        hash1[key] = value2
      end
    end

    hash1
  end
