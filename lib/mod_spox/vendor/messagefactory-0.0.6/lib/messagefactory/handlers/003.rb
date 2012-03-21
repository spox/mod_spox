require 'time'

module MessageFactory
module Handlers
  class Created < Handler

    # Returns type(s) supported
    def types_process
      :'003'
    end

    # string:: string to process
    # Create a new Created message
    # OpenStruct will contain:
    # #type #direction #raw #server #received #created
    # :nodoc: :not.configured 003 spox :This server was created Tue Mar 24 2009 at 15:42:36 PDT'
    def process(string)
      string = string.dup
      m = nil
      begin
        m = mk_struct(string)
        m.type = :created
        orig = string.dup
        string.downcase!
        string.slice!(0)
        m.server = string.slice!(0, string.index(' '))
        string.slice!(0)
        raise 'Bad message type' unless string.slice!(0, string.index(' ')).to_sym == :'003'
        string.slice!(0, string.index('d')+2)
        time = Time.parse(string)
        m.created = time
      rescue
        raise "Failed to parse Created message: #{orig}"
      end
      m
    end
  end
end
end
