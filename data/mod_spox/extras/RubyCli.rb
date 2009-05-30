# IMPORTANT NOTE: This plugin will only function if the PHP executable can be located
require 'timeout'
class RubyCli < ModSpox::Plugin

    include Models
    include Messages::Outgoing

    def initialize(pipeline)
        super(pipeline)
        ruby = Group.find_or_create(:name => 'php')
        admin = Group.filter(:name => 'admin').first
        add_sig(:sig => 'ruby (on|off)', :method => :set_channel, :group => admin, :desc => 'Add or remove channel from allowing ruby command', :params => [:action])
        add_sig(:sig => 'ruby (?!on|off)(.+)', :method => :execute_ruby, :group => ruby, :desc => 'Execute ruby code', :params => [:code])
        add_sig(:sig => 'rubyq (?!on|off)(.+)', :method => :quiet_ruby, :group => ruby, :params => [:code], :desc => 'Execute ruby quietly')
        @channels = Setting.filter(:name => 'rubycli').first
        @channels = @channels.nil? ? [] : @channels.value
    end

    def set_channel(message, params)
        return unless message.is_public?
        if(params[:action] == 'on')
            unless(@channels.include?(message.target.pk))
                @channels << message.target.pk
                tmp = Setting.find_or_create(:name => 'rubycli')
                tmp.value = @channels
                tmp.save
            end
            information message.replyto, 'Ruby command now active'
        else
            unless(@channels.include?(message.target.pk))
                warning message.replyto, 'Ruby command is not currently active in this channel'
            else
                @channels.delete(message.target.pk)
                tmp = Setting.find_or_create(:name => 'rubycli')
                tmp.value = @channels
                tmp.save
                information message.replyto, 'Ruby command is now disabled'
            end
        end
    end

    def quiet_ruby(message, params)
        execute_ruby(message, params, true)
    end

    def execute_ruby(message, params, shh=false)
        return unless @channels.include?(message.target.pk)
        t = Thread.new do
            begin
                result = lambda{ $SAFE = 4; eval(params[:code]) }.call
                result = result.to_s
                @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "#{message.source.nick}: Your result has been truncated. Don't print so much.") if result.size > 300
                @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "#{shh ? '' : 'Result: '}#{result.slice(0..300)}")
            rescue Object => boom
                Logger.error("BOOM: #{boom}")
                @pipeline << Messages::Outgoing::Privmsg.new(message.replyto, "\2RubyCli (error):\2 Exception generated: #{boom.to_s.index(' for ').nil? ? boom.to_s : boom.to_s.slice(0..boom.to_s.index(' for '))}")
            end
        end
        @pipeline << Messages::Internal::TimerAdd.new(self, 10, true){ kill_thread(t, message.replyto) }
    end

    def kill_thread(t, chan)
        if(t.alive?)
            t.kill
            error chan, "Execution timeout."
        end
    end

end