# To change this template, choose Tools | Templates
# and open the template in the editor.

module MessageFactory
module Handlers
  class Quit < Handler
    def types_process
      :QUIT
    end
    # string:: string to process
    # Create a new Quit message
    # OpenStruct will contain:
    # #type #direction #raw #received #source #message
    # :nodoc: :spox!~spox@host QUIT :Ping timeout
    #     :spox!~spox@host QUIT :
    def process(string)
      string = string.dup
      m = mk_struct(string)
      begin
        m.type = :quit
        string.slice!(0)
        m.source = string.slice!(0, string.index(' '))
        string.slice!(0)
        idx = string.index(' ')
        idx ||= string.length
        raise unless string.slice!(0, idx).to_sym == :QUIT
        if(string.index(':'))
          string.slice!(0, string.index(':')+1)
          m.message = string
        else
          m.message = ''
        end
      rescue
        raise "Failed to parse Quit message: #{m.raw}"
      end
      m
    end
  end
end
end