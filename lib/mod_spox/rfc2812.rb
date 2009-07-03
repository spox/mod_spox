module ModSpox
    
    RFC = {
        # basic
        :INVITE => {:value => :INVITE, :handlers => ['Invite']},
        :JOIN => {:value => :JOIN, :handlers => ['Join']},
        :KICK => {:value => :KICK, :handlers => ['Kick']},
        :MODE => {:value => :MODE, :handlers => ['Mode']},
        :NICK => {:value => :NICK, :handlers => ['Nick']},
        :NOTICE => {:value => :NOTICE, :handlers => ['Notice']},
        :PART => {:value => :PART, :handlers => ['Part']},
        :PING => {:value => :PING, :handlers => ['Ping']},
        :PONG => {:value => :PONG, :handlers => ['Pong']},
        :PRIVMSG => {:value => :PRIVMSG, :handlers => ['Privmsg']},
        :QUIT => {:value => :QUIT, :handlers => ['Quit']},
        #client server messages#
        :RPL_WELCOME => {:value => '001', :handlers => ['Welcome']},
        :RPL_YOURHOST => {:value => '002'},
        :RPL_CREATED => {:value => '003', :handlers => ['Created']},
        :RPL_MYINFO => {:value => '004', :handlers => ['MyInfo']},
        :RPL_BOUNCE => {:value => '005', :handlers => ['Bounce']},
        #response replies#
        :RPL_WHOISIDENTIFIED => {:value => '307', :handlers => ['Whois']},
        :RPL_WHOISUSER => {:value => '311', :handlers => ['Whois']},
        :RPL_WHOISSERVER => {:value => '312', :handlers => ['Whois']},
        :RPL_WHOISOPERATOR => {:value => '313', :handlers => ['Whois']},
        :RPL_WHOISIDLE => {:value => '317', :handlers => ['Whois']},
        :RPL_ENDOFWHOIS => {:value => '318', :handlers => ['Whois']},
        :RPL_WHOISCHANNELS => {:value => '319', :handlers => ['Whois']},
        :RPL_NOTOPIC => {:value => '331', :handlers => ['Topic']},
        :RPL_TOPIC => {:value => '332', :handlers => ['Topic']},
        :RPL_TOPICINFO => {:value => '333', :handlers => ['Topic']},
        :RPL_WHOREPLY => {:value => '352', :handlers => ['Who']},
        :RPL_ENDOFWHO => {:value => '315', :handlers => ['Who']},
        :RPL_NAMREPLY => {:value => '353', :handlers => ['Names']},
        :RPL_ENDOFNAMES => {:value => '366', :handlers => ['Names']},
        :RPL_MOTDSTART => {:value => '375', :handlers => ['Motd']},
        :RPL_MOTD => {:value => '372', :handlers => ['Motd']},
        :RPL_ENDOFMOTD => {:value => '376', :handlers => ['Motd']},
        :RPL_LUSERCLIENT => {:value => '251', :handlers => ['LuserClient']},
        :RPL_LUSEROP => {:value => '252', :handlers => ['LuserOp']},
        :RPL_LUSERUNKNOWN => {:value => '253', :handlers => ['LuserUnknown']},
        :RPL_LUSERCHANNELS => {:value => '254', :handlers => ['LuserChannels']},
        :RPL_LUSERME => {:value => '255', :handlers => ['LuserMe']},
        :ERR_ERRONEOUSNICKNAME => {:value => '432', :handlers => ['BadNick']},
        :ERR_NICKNAMEINUSE => {:value => '433', :handlers => ['NickInUse']}
    }
    # i feel kinda dirty after that, but hey, lets keep things interesting!
end