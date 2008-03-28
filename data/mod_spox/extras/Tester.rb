class Tester < Plugin

    def initialize(pipeline)
        super(pipeline)
        Models::Signature.find_or_create(:signature => 'tester', :plugin => name, :method => 'test',
            :description => 'List all available plugins')
        Models::Group.find_or_create(:name => 'testgroup')
        Models::Group.find_or_create(:name => 'anonymous')
    end
    
    def test(message, params)
        @pipeline << Messages::Outgoing::Privmsg.new(message.source.nick, 'This is a test')
    end
end