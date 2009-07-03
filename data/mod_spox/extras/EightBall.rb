require 'mod_spox/messages/outgoing/Privmsg'
class EightBall < ModSpox::Plugin

    include Models

    def initialize(pipeline)
        super
        add_sig(:sig => '8ball .+\?$', :method => :eightball, :desc => 'Ask the magic eightball a question')
        @responses = ['Ask Again Later',
                      'Better Not Tell You Now',
                      'Concentrate and Ask Again',
                      'Don\'t Count on It',
                      'It Is Certain',
                      'Most Likely',
                      'My Reply is No',
                      'My Sources Say No',
                      'No',
                      'Outlook Good',
                      'Outlook Not So Good',
                      'Reply Hazy, Try Again',
                      'Signs Point to Yes',
                      'Yes',
                      'Yes, Definitely',
                      'You May Rely On It']
    end
    
    def eightball(message, params)
        @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, 'shakes magic 8 ball...', true)
        sleep(1)
        reply message.replyto, "#{message.source.nick}: #{@responses[rand(@responses.size) - 1]}"
    end

end