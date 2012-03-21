
module MessageFactory
module Handlers
  class Welcome < Handler
    def types_process
      :'001'
    end
    # string:: string to process
    # Create a new Welcome message
    # OpenStruct will contain:
    # #type #direction #raw #received #message #target #user #server
    # :nodoc: :not.configured 001 spox :Welcome to the unconfigured IRC Network spox!~spox@192.168.0.107
    def process(string)
      string = string.dup
      orig = string.dup
      m = nil
      begin
        m = mk_struct(string)
        m.type = :welcome
        string.slice!(0)
        m.server = string.slice!(0, string.index(' '))
        string.slice!(0)
        raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :'001'
        string.slice!(0)
        m.target = string.slice!(0, string.index(' '))
        string.slice!(0, string.index(':')+1)
        m.message = string.slice!(0, string.rindex(' '))
        string.slice!(0)
        m.user = string
      rescue
        raise "Failed to parse Welcome message: #{orig}"
      end
      m
    end

  end
end
end
