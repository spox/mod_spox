module MessageFactory
module Handlers
  class Invite < Handler
    # Returns type(s) supported
    def types_process
      :INVITE
    end
    # string:: string to process
    # Create a new Invite message
    # OpenStruct will contain:
    # #type #direction #raw #received #source #target #channel
    # :nodoc: :spox!~spox@192.168.0.107 INVITE spox_ :#a
    def process(string)
      string = string.dup
      orig = string.dup
      m = nil
      begin
        m = mk_struct(string)
        m.type = :invite
        string.slice!(0)
        m.source = string.slice!(0, string.index(' '))
        string.slice!(0)
        raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :INVITE
        string.slice!(0)
        m.target = string.slice!(0, string.index(' '))
        string.slice!(0)
        string.slice!(0, string.index(':')+1)
        m.channel = string
      rescue
        raise "Failed to parse Invite message: #{orig}"
      end
      m
    end
  end
end
end
