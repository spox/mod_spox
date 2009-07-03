require 'soap/wsdlDriver'

class UrbanDictionary < ModSpox::Plugin

    include Messages::Outgoing
    include Models

    def initialize(pipeline)
        super(pipeline)
        add_sig(:sig => 'udefine (?!key)((\d+ )?(.+))', :method => :define, :desc => 'Find the definition of a word or phrase', :params => [:fullmatch, :number, :term])
        add_sig(:sig => 'udefine key (.+)', :method => :key, :group => Models::Group.filter(:name => 'admin').first, :desc => 'Set API key', :params => [:key])
    end

    def define(message, params)
        key = Config.val(:urban_key)
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
                    reply message.replyto, "Error: Definition number #{result+1} for term: #{params[:term]} not found."
                else
                    defin = defs[result].definition.length > 390 ? defs[result].definition.slice(0..390) + " *[CUT]*" : defs[result].definition
                    exp = defs[result].example.length > 390 ? defs[result].example.slice(0..390) + " *[CUT]*" : defs[result].example
                    output << "Definition for \2#{defs[result].word}:\2"
                    output << Helpers.convert_entities(defin.gsub(/[\r\n\s]+/, ' '))
                    output << "\2Example usage:\2 #{Helpers.convert_entities(exp.gsub(/[\r\n\s]+/, ' '))}" if exp.length > 0
                    reply message.replyto, output
                end
            rescue Timeout::Error
                reply message.replyto, "Failed to establish connection to server."
            rescue Object => boom
                reply message.replyto, "Unexpected error encountered: #{boom}"
            end
        else
            reply message.replyto, "\2Error:\2 No valid key available for dictionary"
        end
    end

    def key(message, params)
        if(message.is_public?)
            reply message.replyto, 'I don\'t set keys in public'
        else
            Config.set(:urban_key, params[:key])
            reply message.replyto, 'Urban Dictionary API key has been set.'
        end
    end

end