
require 'timeout'
class RubyCli < ModSpox::Plugin

    include Models
    include Messages::Outgoing

    def initialize(pipeline)
        super(pipeline)
        ruby = Group.find_or_create(:name => 'ruby')
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
    
    # we fork into a separate process for more control
    # over untrusted code
    def execute_ruby(message, params, shh=false)
        return unless @channels.include?(message.target.pk)
        rd, wr = IO.pipe
        cid = Kernel.fork do
            rd.close
            result = nil
            begin
                result = lambda{$SAFE=4; eval(params[:code])}.call
            rescue Object => boom
                result = boom
            ensure
                wr.write [Marshal.dump(result)].pack('m')
            end
        end
        if(cid)
            Database.reset_connections
            begin
                result = nil
                Timeout::timeout(5) do
                    wr.close
                    result = rd.read
                    rd.close
                end
                result = result.size > 0 ? Marshal.load(result.unpack('m')[0]) : ''
                if(result.is_a?(Exception))
                    error message.replyto, "Exception generated: #{result.to_s.index(' for ').nil? ? result.to_s : result.to_s.slice(0..result.to_s.index(' for '))}"
                else
                    result = result.to_s
                    reply message.replyto, "#{message.source.nick}: Your result has been truncated. Don't print so much." if result.size > 300
                    reply message.replyto, "#{shh ? '' : 'Result: '}#{result.slice(0..300)}"
                end
            rescue Timeout::Error
                error message.replyto, 'Execution timeout reached.'
                Logger.warn("Child process #{cid} to be killed")
                Process.kill('KILL', cid)
                Logger.warn("Child process #{cid} has been killed")
            rescue Object => boom
                error message.replyto, "Unknown error encountered: #{boom}"
            ensure
                Process.wait(cid, Process::WNOHANG)
                Logger.info("RubyCli process has exited.")
            end
        end
    end

end