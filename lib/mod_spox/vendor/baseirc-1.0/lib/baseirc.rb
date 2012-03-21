# BaseIRC module
module BaseIRC
  # IRC class for sending communcation to an IRC server
  class IRC
    # s:: Socket to send through
    # Create a new IRC object
    def initialize(s)
      @socket = nil
      self.socket = s
    end

    # s:: Socket to send through
    # Set the socket to use
    def socket=(s)
      unless(s.respond_to?(:<<))
        raise ArgumentError.new('Please supply a socket')
      end
      @socket = s
    end
    
    # Return currently used socket
    def socket
      @socket
    end

    # password:: Password to send
    # Sends PASS message
    def pass(password)
      @socket << "PASS #{password}"
    end

    # nick:: Nick to send
    # Sends NICK message
    def nick(nick)
      @socket << "NICK #{nick}"
    end

    # u:: Username
    # m:: Mode
    # r: Real name
    # Sends USER message
    def user(u, m, r)
      @socket << "USER #{u} #{m} * :#{r}"
    end

    # n:: Name
    # p:: Password
    # Sends OPER message
    def oper(n, p)
      @socket << "OPER #{n} #{p}"
    end

    def mode(t, m, c=nil)
      if(c)
        @socket << "MODE #{c} #{m} #{t}"
      else
        @socket << "MODE #{t} #{m}"
      end
    end

    # message:: Quit message
    # Sends QUIT message
    def quit(message)
      @socket << "QUIT :#{message}"
    end

    # s:: Server
    # c:: Comment
    # Sends SQUIT message
    def squit(s, c)
      @socket << "SQUIT #{s} :#{c}"
    end

    # c:: Channel
    # k:: Key
    # Sends JOIN message
    def join(c, k=nil)
      @socket << "JOIN #{c} #{k}".strip
    end

    # c:: Channel
    # r:: Reason
    # Sends PART message
    def part(c, r='')
      @socket << "PART #{c} :#{r}"
    end

    # c:: Channel
    # t:: topic
    # Sends TOPIC message
    def topic(c, t)
      @socket << "TOPIC #{c} :#{t}"
    end

    # c:: Channel
    # t:: Target server
    # Sends NAMES message
    def names(c, t=nil)
      @socket << "NAMES #{c} #{t}".strip
    end

    # c:: Channel
    # Sends LIST message
    def list(c=nil)
      @socket << "LIST #{c}".strip
    end

    # n:: Nick
    # c:: Channel
    # Sends INVITE message
    def invite(n, c)
      @socket << "INVITE #{n} #{c}"
    end

    # n:: Nick
    # c:: Channel
    # r:: Reason
    # Sends KICK message
    def kick(n, c, r)
      @socket << "KICK #{c} #{n} :#{r}"
    end

    # t:: Target
    # m:: Message
    # Sends PRIVMSG message

    def privmsg(t, m)
      @socket << "PRIVMSG #{t} :#{m}"
    end

    # t:: Target
    # m:: Message
    # Sends NOTICE message
    def notice(t, m)
      @socket << "NOTICE #{t} :#{m}"
    end

    # t:: Target
    # Sends MOTD message
    def motd(t)
      @socket << "MOTD #{t}"
    end

    # m:: Mask
    # t:: Target
    # Sends LUSERS message
    def lusers(m, t)
      @socket << "LUSERS #{m} #{t}"
    end

    # t:: Target
    # Sends VERSION message
    def version(t)
      @socket << "VERSION #{t}"
    end

    # q:: Query (single character within set a-z)
    # t:: Target
    # Sends STATS message
    def stats(q, t)
      unless(q =~ /^[a-z]$/)
        raise ArgumentError.new('Query must be a single character')
      end
      @socket << "STATS #{q} #{t}"
    end

    # s:: Server
    # m:: Mask
    # Sends LINKS message
    def links(s, m)
      @socket << "LIST #{s} #{m}"
    end

    # t:: Target
    # Sends TIME message
    def time(t)
      @socket << "TIME #{t}"
    end

    # t:: Target server
    # p:: Port
    # r:: Remove server
    # Sends CONNECT message
    def connect(t, p, r)
      @socket << "CONNECT #{t} #{p} #{r}"
    end

    # t:: Target
    # Sends TRACE message
    def trace(t)
      @socket << "TRACE #{t}"
    end

    # t:: Target
    # Sends ADMIN message
    def admin(t)
      @socket << "ADMIN #{t}"
    end

    # t:: Target
    # Sends INFO message
    def info(t)
      @socket << "INFO #{t}"
    end

    # m:: Mask
    # t:: Type
    # Sends SERVLIST message
    def servlist(m, t)
      @socket << "SERVLIST #{m} #{t}"
    end

    # s:: Service name
    # m:: Message
    # Sends SQUERY message
    def squery(s, m)
      @socket << "SQUERY #{s} #{m}"
    end

    # m:: Mask
    # o:: Ops only
    # Sends WHO message
    def who(m, o=false)
      o = o ? 'o' : ''
      @socket << "WHO #{m} #{o}".strip
    end

    # n:: Nick
    # s:: Server
    # Sends WHOIS message
    # Sends WHOIS message to server
    def whois(n, s=nil)
      @socket << "WHOIS #{[s,n].compact.join(' ')}"
    end

    # n:: Nick
    # c:: Count
    # t:: Target
    # Sends WHOWAS message
    def whowas(n, c=nil, t=nil)
      @socket << "WHOWAS #{[n,c,t].compact.join(' ')}"
    end

    # n:: Nick
    # c:: Comment
    # Sends KILL message
    def kill(n, c)
      @socket << "KILL #{n} :#{c}"
    end

    # m:: Message
    # Sends PING message
    def ping(m=nil)
      @socket << "PING #{m}".strip
    end

    # s:: Server
    # m:: Message
    # Sends PONG message
    def pong(s, m)
      @socket << "PONG #{s} #{m}"
    end

    # m:: Message
    # Sends AWAY message to mark as away
    def away(m=nil)
      @socket << "AWAY :#{m}"
    end

    # Sends AWAY message to mark as unaway
    def unaway
      @socket << "AWAY"
    end

    # Sends REHASH message
    def rehash
      @socket << "REHASH"
    end

    # Sends DIE message
    def die
      @socket << "DIE"
    end

    # Sends RESTART message
    def restart
      @socket << "RESTART"
    end

    # n:: Nick
    # t:: Target
    # c:: Channel
    # Sends SUMMON message
    def summon(n, t, c)
      @socket << "SUMMON #{n} #{t} #{c}"
    end

    # t:: Target
    # Sends USERS message
    def users(t)
      @socket << "USERS #{t}"
    end

    # m:: Message
    # Sends WALLOPS message
    def wallops(m)
      @socket << "WALLOPS :#{m}"
    end

    # n:: Nick
    # Sends USERHOST message to server
    def userhost(n)
      @socket << "USERHOST #{n}"
    end

    # n:: Nick
    # Sends ISON message to server
    def ison(n)
      @socket << "ISON #{n}"
    end

    # m:: Raw string
    # Send raw message
    def raw(m)
      @socket << m
    end
  end
end
