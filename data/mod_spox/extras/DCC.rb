['ipaddr', 'socket', 'timeout'].each{|f| require f}

class DCC < ModSpox::Plugin

    include Models

    def initialize(pipeline)
        super
        group = Group.find_or_create(:name => 'dcc')
        admin = Group.find_or_create(:name => 'admin')
        add_sig(:sig => 'file list(\s(.+))?', :method => :file_list, :desc => 'List available DCC files', :group => group, :params => [:pattern])
        add_sig(:sig => 'file get (.+)', :method => :file_get, :desc => 'Download file', :group => group, :params => [:filename])
        add_sig(:sig => 'file ports (\d+)-(\d+)', :method => :set_ports, :desc => 'Set allowed DCC ports', :group => admin, :params => [:start, :end])
        add_sig(:sig => 'file adddir (.+)', :method => :add_dir, :desc => 'Add directory to file list', :group => admin, :params => [:dir])
        add_sig(:sig => 'file rmdir (\d+)', :method => :rm_dir, :desc => 'Remove directory from file list', :group => admin, :params => [:dir])
        add_sig(:sig => 'file show dir', :method => :show_dirs, :desc => 'Show directories available to file list', :group => admin)
        add_sig(:sig => 'file show ports', :method => :show_ports, :desc => 'Show allowed ports', :group => admin)
        add_sig(:sig => 'file max wait(\s(\d+))?', :method => :max_wait, :desc => 'Show/set timeout for accepting files', :group => admin, :params => [:wait])
        add_sig(:sig => 'dcc chat', :method => :dcc_chat, :desc => 'Start a DCC chat with the bot (useful if behind firewall', :group => group)
        @servers = {}
        @ports = Setting[:dcc_ports]
        @ports = {:start => 49152, :end => 65535} if @ports.nil?
        @dirs = Setting.find_or_create(:name => 'dcc_dirs').value
        @dirs = [] unless @dirs.is_a?(Array)
        @max_wait = Setting[:dcc_max_wait]
        @max_wait = @max_wait.nil? ? 60 : @max_wait.to_i
    end

    def file_list(message, params)
        matches = []
        pattern = params[:pattern] ? Regexp.new(params[:pattern].strip!) : nil
        @dirs.each do |path|
            dir = Dir.new(path)
            dir.each do |file|
                next if File.directory?("#{dir.path}/#{file}") || (file[0] == 46 || file[0] == '.') || !File.readable?("#{dir.path}/#{file}")
                unless(pattern.nil?)
                    if(pattern.match(file))
                        matches << dir.path + '/' + file + " - #{Helpers.format_size(File.size(dir.path + '/' + file))}"
                    end
                else
                    matches << dir.path + '/' + file  + " - #{Helpers.format_size(File.size(dir.path + '/' + file))}"
                end
            end
        end
        output = ["\2Files in available list:\2 (matching: #{params[:pattern] ? params[:pattern] : ''})"]
        output = output + matches
        reply message.replyto, output
    end

    def file_get(message, params)
        @try = 0
        socket = nil
        port = 0
        unless(@dirs.include?(File.dirname(params[:filename])))
            reply message.replyto, "\2Error:\2 #{params[:filename]} is not within the allowed directories"
        else
            while(socket.nil? && @try < 3) do
                begin
                    port = rand(@ports[:end] - @ports[:start]) + @ports[:start]
                    socket = Object::Socket.new(Object::Socket::AF_INET, Object::Socket::SOCK_STREAM, 0)
                    addr = Object::Socket.pack_sockaddr_in(port, me.address)
                    socket.bind(addr)
                    initialize_getter(socket, params[:filename])
                rescue Object => boom
                    Logger.warn("Failed to initialize DCC TCPServer. Reason: #{boom}")
                    @try += 1
                    socket = nil
                    port = nil
                end
            end
            if(socket.nil?)
                reply message.replyto, "\2Error:\2 Failed to initialize file getter process."
            else
                ip = IPAddr.new(me.address).to_i
                @pipeline << Messages::Outgoing::Privmsg.new(message.source, "SEND #{File.basename(params[:filename])} #{ip} #{port} #{File.size(params[:filename])}", false, true, 'DCC')
            end
        end
    end

    def max_wait(message, params)
        wait = params[:wait].nil? ? nil : params[:wait].strip
        unless(wait.nil?)
            @max_wait = wait.to_i
            record = Setting.find_or_create(:name => 'dcc_max_wait')
            record.value = wait
            record.save
            reply message.replyto, "Timeout for file download changed to: #{@max_wait} seconds"
        else
            reply message.replyto, "Timeout for file download is: #{@max_wait} seconds"
        end
    end

    def set_ports(message, params)
        if(params[:start].to_i > 1024 && params[:end].to_i < 65536)
            @ports = {:start => params[:start].to_i, :end => params[:end].to_i}
            record = Setting.find_or_create(:name => 'dcc_ports')
            record.value = @ports
            record.save
            reply message.replyto, "File ports have been updated to: #{@ports[:start]} - #{@ports[:end]}"
        else
            reply message.replyto, "\2Error:\2 Ports given are out of acceptable range (1025 - 65535)"
        end
    end

    def add_dir(message, params)
        if(File.readable?(params[:dir]))
            if(@dirs.include?(dir))
                reply message.replyto, "\2Error:\2 Given directory is already in available list. (#{params[:dir]})"
            else
                @dirs << dir
                record = Setting.find_or_create(:name => 'dcc_dirs')
                record.value = @dirs
                record.save
                reply message.replyto, "New directory added to DCC directory list: #{params[:dir]}"
            end
        else
            reply message.replyto, "\2Error:\2 Given directory is not readable. (#{params[:dir]})"
        end
    end

    def rm_dir(message, params)
        if(@dirs.include?(params[:dir]))
            @dirs.delete(params[:dir])
            record = Setting.find_or_create(:name => 'dcc_dirs')
            record.value = @dirs
            record.save
            reply message.replyto, "DCC directory successfully updated"
        else
            reply message.replyto, "\2Error:\2 Failed to find directory: #{params[:dir]} in available directory list"
        end
    end

    def show_dirs(message, params)
        output = []
        output << "\2Directories available for DCC file list:\2"
        output += @dirs
        reply message.replyto, output
    end

    def show_ports(message, params)
        reply message.replyto, "\2Allowed Ports:\2 #{@ports[:start]} - #{@ports[:end]}"
    end

    def dcc_chat(message, params)
        @pipeline << Messages::Internal::DCCListener.new(message.source)
    end

    private

    def initialize_getter(socket, filename)
        @servers[socket.object_id] = Thread.new do
            client = nil
            addrinfo = nil
            cport = nil
            cip = nil
            begin
                Timeout::timeout(@max_wait) do
                    socket.listen(5)
                    client, addrinfo = socket.accept
                    cport, cip = Object::Socket.unpack_sockaddr_in(addrinfo)
                end
                Logger.info("Sending file: #{filename} to IP: #{cip}:#{cport}")
                file = File.new(filename)
                until((line = file.gets).nil?) do
                    client << line
                end
                Logger.info("Sending of file: #{filename} to IP: #{addrinfo} is now complete")
            rescue Timeout::Error => boom
                Logger.warn("Error sending file: #{filename}. Timeout exceeded (#{@max_wait} seconds)")
            rescue Object => boom
                Logger.warn("Error sending file: #{filename}. Unknown reason: #{boom}")
            ensure
                socket.close
                client.close
                @servers.delete(socket.object_id)
            end
        end
    end

end