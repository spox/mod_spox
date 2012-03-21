
module MessageFactory
module Handlers
  class LuserChannels < Handler
    def types_process
      :'254'
    end
    # string:: string to process
    # Create a new LuserChannels message
    # OpenStruct will contain:
    # #type #direction #raw #received #server #target #num_channels #message
    # :nodoc: :crichton.freenode.net 254 spox 24466 :channels formed
    def process(string)
      string = string.dup
      orig = string.dup
      m = nil
      begin
        m = mk_struct(string)
        m.type = :luserchannels
        string.slice!(0)
        m.server = string.slice!(0, string.index(' '))
        string.slice!(' ')
        raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :'254'
        string.slice!(0)
        m.target = string.slice!(0, string.index(' '))
        string.slice!(0)
        m.num_channels = string.slice!(0, string.index(' '))
        string.slice!(0, string.index(':')+1)
        m.message = string
      rescue
        raise "Failed to parse LuserChannels message: #{orig}"
      end
      m
    end
  end
end
end