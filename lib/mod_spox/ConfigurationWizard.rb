require 'pstore'
module ModSpox
    class ConfigurationWizard
        def initialize(path=nil)
            @store_path = path ? path : '/tmp'
        end

        def set_path(path)
            @store_path = path
        end

        def run
            ensure_path
            populate_hashes
            puts "## mod_spox configuration wizard ##\n\n"
            ask_bot_questions
            ask_connection_questions
            puts "\n## Configuration is now complete ##"
        end

        private

        def ensure_path
            unless(File.writable?(@store_path))
                raise "Given path is not writable (#{@store_path})"
            end
        end

        def ask_bot_questions
            @bot.transaction do
                @bot[:nick] = get_input('IRC Nick', /^[A-Za-z\|\\\{\}\[\]\^\`~\_\-]+[A-Za-z0-9\|\\\{\}\[\]\^\`~\_\-]*$/, @bot[:nick])
                @bot[:password] = get_input('IRC Password', /.+/, @bot[:password])
                @bot[:username] = get_input('IRC Username', /.+/, @bot[:username])
                @bot[:realname] = get_input('IRC Real Name', /.+/, @bot[:realname])
            end
        end

        def ask_connection_questions
            @connection.transaction do
                until(get_input('Add IRC Server', /^(yes|no)$/i, 'yes') == 'no') do
                    s = get_input('Server Host', /.+/)
                    pt = get_input('Server Port', /^\d+$/, '6667')
                    @connection[:servers] << {:server => s, :port => pt}
                end
                @connection[:burst_lines] = get_input('Socket burst limit (lines)', /^\d+$/, @connection[:burst_lines])
                @connection[:burst_in] = get_input('Socket burst duration (seconds)', /^\d+$/, @connection[:burst_in])
                @connection[:burst_delay] = get_input('Socket burst delay (seconds)', /^\d+$/, @connection[:burst_delay])
            end
        end

        def ask_admin_questions
            @admin.transations do
                @admin[:nick] = get_input('Administrator nick', /.+/, @admin[:nick])
                @admin[:password] = get_input('Administrator password:', /.+/, @admin[:password])
            end
        end

        # Populate the hashes from PStore files
        def populate_hashes
            @bot = PStore.new("#{@store_path}/bot.pstore")
            @connection = PStore.new("#{@store_path}/connection.pstore")
            @admin = PStore.new("#{@store_path}/admin.pstore")
            default_connection
            default_bot
        end

        # Set default values for bot
        def default_bot
            return if @bot.transaction{ @bot[:nick] }
            @bot.transaction do
                @bot[:nick] = 'mod_spox'
                @bot[:password] = ''
                @bot[:username] = 'mod_spox'
                @bot[:realname] = 'mod_spox IRC robot'
            end
        end

        # Set default values for connection
        def default_connection
            return if @connection.transaction{ @connection[:servers] }
            @connection.transaction do
                @connection[:servers] = []
                @connection[:burst_in] = 2
                @connection[:burst_delay] = 2
                @connection[:burst_lines] = 3
            end
        end

        # pattern:: regex response must match
        # default:: default value if response is empty
        # echo:: echo user's input
        # Reads users input
        def read_input(pattern=nil, default=nil)
            if(pattern && !pattern.is_a?(Regexp))
                raise 'Pattern must be a Regexp'
            end
            response = $stdin.readline
            response.strip!
            set = !response.empty?
            if(pattern)
                response = nil unless response =~ pattern
            end
            if(default && !set)
                response = default
            end
            response
        end

        # output:: to send before user input
        # regex:: pattern user input must match
        # echo:: echo user's input
        # default:: default value if no value is entered
        # Writes given output and retrieves appropriate value
        def get_input(output, regex=nil, default=nil)
            response = nil
            until(response) do
                print output
                if(default)
                    print " [#{default}]: "
                else
                    print ': '
                end
                $stdout.flush
                response = read_input(regex, default)
            end
            response
        end
    end
end
