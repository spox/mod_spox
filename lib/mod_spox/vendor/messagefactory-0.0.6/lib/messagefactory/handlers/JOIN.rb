
module MessageFactory
module Handlers
  class Join < Handler
    def types_process
      :JOIN
    end
    # string:: string to process
    # Create a new Join message
    # OpenStruct will contain:
    # #type #direction #raw #received #source #channel
    # :nodoc: :mod_spox!~mod_spox@host JOIN :#m
    def process(string)
      string = string.dup
      orig = string.dup
      m = nil
      begin
        m = mk_struct(string)
        m.type = :join
        string.slice!(0)
        m.source = string.slice!(0, string.index(' '))
        string.slice!(0)
        raise 'error' unless string.slice!(0, string.index(' ')).to_sym == :JOIN
        string.slice!(0, string.index(':')+1)
        m.channel = string
      rescue
        raise "Failed to parse Join message: #{orig}"
      end
      m
    end
  end
end
end
