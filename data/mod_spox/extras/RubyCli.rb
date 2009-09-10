
require 'timeout'
class RubyCli < ModSpox::Plugin

    include Models
    include Messages::Outgoing

    def initialize(pipeline)
        super(pipeline)
        @path = Config.val(:plugin_directory) + '/rubycli'
        unless(File.directory?(@path))
            FileUtils.mkdir_p(@path)
        end
        @exec = Config.val(:rbexec)
        if(@exec.nil?)
            result = Helpers.safe_exec('which ruby')
            raise NoInterpreter.new if result.empty?
            @exec = 'ruby'
        end
        ruby = Group.find_or_create(:name => 'ruby')
        admin = Group.filter(:name => 'admin').first
        add_sig(:sig => 'ruby (on|off)', :method => :set_channel, :group => admin, :desc => 'Add or remove channel from allowing ruby command', :params => [:action])
        add_sig(:sig => 'ruby (?!on|off)(.+)', :method => :execute_ruby, :group => ruby, :desc => 'Execute ruby code', :params => [:code])
        add_sig(:sig => 'rubyq (?!on|off)(.+)', :method => :quiet_ruby, :group => ruby, :params => [:code], :desc => 'Execute ruby quietly')
        add_sig(:sig => 'rubyexec( (\S+))?', :method => :set_exec, :params => [:exec], :group => admin, :desc => 'Set custom ruby executable')
        @channels = Setting.filter(:name => 'rubycli').first
        @channels = @channels.nil? ? [] : @channels.value
    end

    def set_exec(m, params)
        if(params[:exec])
            path = params[:exec].strip
            unless(path == 'none')
                if(File.executable?(path))
                    Config.set(:rbexec, path)
                    @exec = path
                    information m.replyto, "Ruby executable path has been updated: #{@exec}"
                else
                    error m.replyto, 'Path given is not a valid executable path'
                end
            else
                Config.filter(:name => 'rbexec').destroy
                @exec = 'ruby'
                information m.replyto, 'Bot is now using default ruby executable'
            end
        else
            information m.replyto, "Executable path is: #{@exec}"
        end
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
        filepath = @path + "/#{rand(99999)}.bot.rb"
        file = File.open(filepath, 'w')
        file.write("puts lambda{$SAFE=4; #{params[:code]}}.call")
        file.close
        begin
            output = Helpers.safe_exec("#{@exec} #{filepath} 2>&1 | head -n 4")
            if(output.slice(0, filepath.length) == filepath)
                output.slice!(0, filepath.length)
                output = output.slice!(0, output.index("\n").nil? ? output.length : output.index("\n"))
                error message.replyto, output
            elsif(output.length > 300)
                reply message.replyto, "#{message.source.nick}: Your result has been truncated. Don't print so much."
                output = output.slice(0, 300)
            else
                reply message.replyto, "Result: #{output}"
            end
            File.delete(filepath)
        rescue Timeout::Error => boom
            reply message.replyto, "\2Error:\2 Timeout reached: #{boom}"
        rescue Object => boom
            reply message.replyto, "\2Error:\2 Script execution terminated. (#{boom})"
            File.delete(filepath)
        end
    end

end