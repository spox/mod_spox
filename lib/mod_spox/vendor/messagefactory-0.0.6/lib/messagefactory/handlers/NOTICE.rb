# To change this template, choose Tools | Templates
# and open the template in the editor.

module MessageFactory
module Handlers
  class Notice < Handler
    def types_process
      :NOTICE
    end
    # string:: string to process
    # Create a new Notice message
    # OpenStruct will contain:
    # #type #direction #raw #received #source #target #message
    # :nodoc: :spox!~spox@some.host NOTICE spax :test
    # :nodoc: :spox!~spox@some.host NOTICE #mod_spox :test
    def process(string)
      string = string.dup
      m = mk_struct(string)
      begin
        m.type = :notice
        string.slice!(0)
        m.source = string.slice!(0, string.index(' '))
        string.slice!(0)
        raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :NOTICE
        string.slice!(0)
        m.target = string.slice!(0, string.index(' '))
        string.slice!(0, string.index(':')+1)
        m.message = string
      rescue
        raise "Failed to parse Notice message: #{m.raw}"
      end
      m
    end
  end
end
end
