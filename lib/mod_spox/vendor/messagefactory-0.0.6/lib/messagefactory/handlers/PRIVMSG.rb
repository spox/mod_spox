# To change this template, choose Tools | Templates
# and open the template in the editor.

module MessageFactory
module Handlers
  class Privmsg < Handler
    def types_process
      :PRIVMSG
    end
    # string:: string to process
    # Create a new Privmsg message
    # OpenStruct will contain:
    # #type #direction #raw #received #source #target #message
    # :nodoc: I thoguht about adding in #public and #private methods and
    # something for the nick a message is addressing, but we want
    # to keep this stuff simple, so we will let the implementation program
    # worry about extras like that.
    # :nodoc: :spox!~spox@host PRIVMSG #m :foobar
    # :nodoc: :spox!~spox@host PRIVMSG mod_spox :foobar
    def process(string)
      string = string.dup
      m = mk_struct(string)
      begin
        m.type = :privmsg
        string.slice!(0)
        m.source = string.slice!(0, string.index(' '))
        string.slice!(0)
        raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :PRIVMSG
        string.slice!(0)
        m.target = string.slice!(0, string.index(' '))
        string.slice!(0, string.index(':')+1)
        m.message = string
      rescue
        raise "Failed to parse Privmsg message: #{m.raw}"
      end
      m
    end
  end
end
end