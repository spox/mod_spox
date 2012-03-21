# To change this template, choose Tools | Templates
# and open the template in the editor.

module MessageFactory
module Handlers
  class Pong < Handler
    def types_process
      :PONG
    end
    # string:: string to process
    # Create a new Ping message
    # OpenStruct will contain:
    # #type #direction #raw #received #server #message
    # :nodoc: :swiftco.wa.us.dal.net PONG swiftco.wa.us.dal.net :FOO
    def process(string)
      string = string.dup
      m = mk_struct(string)
      begin
        m.type = :pong
        string.slice!(0)
        m.server = string.slice!(0, string.index(' '))
        string.slice!(0)
        raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :PONG
        if(string.index(':'))
          string.slice!(0, string.index(':')+1)
          m.message = string
        else
          m.message = ''
        end
      rescue
        raise "Failed to parse Pong message: #{m.raw}"
      end
      m
    end
  end
end
end