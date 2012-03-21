# To change this template, choose Tools | Templates
# and open the template in the editor.

module MessageFactory
module Handlers
  class Who < Handler
    def initialize
      @cache = {}
    end
    def types_process
      [:'352', :'315']
    end
    # string:: string to process
    # Create a new Who message
    # OpenStruct will contain:
    # #type #direction #raw #received #source #channel #message
    # :nodoc:   Nick style:
    # :swiftco.wa.us.dal.net 352 spox * ~metallic codemunkey.net punch.va.us.dal.net metallic H :2 Sean Grimes
    # :swiftco.wa.us.dal.net 315 spox metallic :End of /WHO list.
    #       Channel style:
    # :swiftco.wa.us.dal.net 352 spox #php ~chendo 24.47.233.220.static.exetel.com.au punch.va.us.dal.net chendo H@ :2 chendo
    # :swiftco.wa.us.dal.net 315 spox #php :End of /WHO list.
    def process(string)
      string = string.dup
      orig = string.dup
      m = nil
      begin
        server = string.slice!(0, string.index(' '))
        string.slice!(0)
        action = string.slice!(0, string.index(' ')).to_sym
        string.slice!(0)
        string.slice!(0, string.index(' ')+1)
        if(action == :'352')
          m = who_content(string, orig)
        elsif(action == :'315')
          m = who_end(string, orig)
        else
          raise
        end
      rescue
        raise "Failed to parse Who message: #{orig}"
      end
      m
    end

    def who_content(string, orig)
      name = string.slice!(0, string.index(' '))
      string.slice!(0)
      nick = OpenStruct.new
      nick.username = string.slice!(0, string.index(' '))
      string.slice!(0)
      nick.host = string.slice!(0, string.index(' '))
      string.slice!(0)
      nick.irc_host = string.slice!(0, string.index(' '))
      string.slice!(0)
      nick.nick = string.slice!(0, string.index(' '))
      string.slice!(0)
      status = string.slice!(0, string.index(' '))
      string.slice!(0, string.index(':')+1)
      nick.hops = string.slice!(0, string.index(' ')).to_i
      string.slice!(0)
      nick.real_name = string
      target = name == '*' ? nick.nick : name
      m = fetch_target(target, orig, name != '*')
      m.nicks << nick
      m.ops.push nick if status.index('@')
      m.voice.push nick if status.index('+')
      m.raw << orig
      nil
    end

    def fetch_target(target, orig, channel=true)
      unless(@cache[target])
        m = mk_struct(orig)
        m.type = :who
        m.raw = []
        m.nicks = []
        if(channel)
          m.ops = []
          m.voice = []
          m.channel = target
        end
        @cache[target] = m
      end
      @cache[target]
    end

    def who_end(string, orig)
      name = string.slice!(0, string.index(' '))
      m = @cache[name]
      if(m)
        @cache.delete(name)
        m.raw << orig
      end
      m
    end
  end
end
end
