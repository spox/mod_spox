require 'soap/wsdlDriver'

class UrbanDictionary < ModSpox::Plugin

    include Messages::Outgoing
    include Models

    def initialize(pipeline)
        super(pipeline)
        begin
            require 'htmlentities'
        rescue Object => boom
            Logger.log('Error: This plugin requires the HTMLEntities gem. Please install and reload plugin.')
            raise Exceptions::BotException.new("Missing required HTMLEntities library")
        end
        Signature.find_or_create(:signature => 'udefine (?!key)(\d+)? ?(.+)', :plugin => name, :method => 'define',
            :description => 'Find the definition of a word or phrase').params = [:number, :term]
        Signature.find_or_create(:signature => 'udefine key (.+)', :plugin => name, :method => 'key',
            :group_id => Models::Group.filter(:name => 'admin').first.pk, :description => 'Set API key').params = [:key]
        @coder = HTMLEntities.new
    end

    def define(message, params)
        key = Config[:urban_key]
        if(key)
            site = 'http://api.urbandictionary.com/soap?wsdl'
            result = params[:number] ? params[:number].to_i - 1 : 0
            begin
                proxy = SOAP::WSDLDriverFactory.new(site).create_rpc_driver
                #udict = SOAP::RPC::Driver.new(site, 'urn:UrbanSearch')
                #udict.add_method('lookup', 'key', 'term')
                defs = proxy.lookup(key, params[:term])
                #defs = udict.lookup(key, params[:term])
                output = []
                if defs.size < result + 1
                    @pipeline << Privmsg.new(message.replyto, "Error: Definition number #{result+1} for term: #{params[:term]} not found.")
                else
                    defin = defs[result].definition.length > 500 ? defs[result].definition.slice(0..500) + " *[CUT]*" : defs[result].definition
                    exp = defs[result].example.length > 500 ? defs[result].example.slice(0..500) + " *[CUT]*" : defs[result].example
                    output << "Definition for \2#{defs[result].word}:\2"
                    output << @coder.decode(defin.gsub(/[\r\n\s]+/, ' '))
                    output << "\2Example usage:\2 #{@coder.decode(exp.gsub(/[\r\n\s]+/, ' '))}" if exp.length > 0
                    reply message.replyto, output
                end
            rescue Timeout::Error
                @pipeline << Privmsg.new(message.replyto, "Failed to establish connection to server.")
            rescue Object => boom
                @pipeline << Privmsg.new(message.replyto, "Unexpected error encountered: #{boom}")
            end
        else
            @pipeline << Privmsg.new(message.replyto, "\2Error:\2 No valid key available for dictionary")
        end
    end

    def key(message, params)
        if(message.is_public?)
            @pipeline << Privmsg.new(message.replyto, 'I don\'t set keys in public')
        else
            Config[:urban_key] = params[:key]
            @pipeline << Privmsg.new(message.replyto, 'Urban Dictionary API key has been set.')
        end
    end

end