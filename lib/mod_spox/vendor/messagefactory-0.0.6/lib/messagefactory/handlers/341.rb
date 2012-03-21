
module MessageFactory
module Handlers
  class Inviting < Handler
    def types_process
      :'341'
    end
    # string:: string to process
    # Create a new Inviting message
    # OpenStruct will contain:
    # #type #direction #raw #received #server #source #target #channel
    # :nodoc: :not.configured 341 spox spox_ #a
    def process(string)
      string = string.dup
      orig = string.dup
      m = nil
      begin
        m = mk_struct(string)
        m.type = :inviting
        string.slice!(0)
        m.server = string.slice!(0, string.index(' '))
        string.slice!(0)
        raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :'341'
        string.slice!(0)
        m.source = string.slice!(0, string.index(' '))
        string.slice!(0)
        m.target = string.slice!(0, string.index(' '))
        string.slice!(0)
        m.channel = string
      rescue
        raise "Failed to parse Inviting message: #{orig}"
      end
      m
    end
  end
end
end
