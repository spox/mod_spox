require 'spockets/Exceptions'
require 'spockets/Watcher'

module Spockets

    class Spockets

        # :pool:: ActionPool if you would like to consolidate
        # :clean:: Clean string. Set to true for default or 
        #          provide a block to clean strings
        # creates a new holder
        def initialize(args={})
            @sockets = {}
            @sync = true
            @watcher = Watcher.new(:sockets => @sockets, :clean => args[:clean], :pool => args[:pool])
        end
        
        # Will sockets be resynced
        def sync?
            @sync.dup
        end
        
        # b:: boolean
        # Set whether resync on addition
        def sync=(b)
            @sync = b != false
        end

        # b:: boolean to force sync status to true
        # Resync sockets in Watcher
        def sync(b = nil)
            @sync = b != false unless b.nil?
            if(@sync)
                begin
                    @watcher.sync
                rescue NotRunning
                    start
                end
            end
        end

        # socket:: socket to listen to
        # data:: data to be passed to block. NOTE: string from 
        # socket will be prepended to argument list
        # block:: block to execute when activity is received
        # Adds a socket to the list to listen to. When a string
        # is received on the socket, it will send it to the block
        # for processing
        def add(socket, *data, &block)
            raise ArgumentError.new('Block must be supplied') unless block_given?
            raise ArgumentError.new('Block must allow at least one argument') if block.arity == 0
            if(block.arity > 0 && block.arity != (data.size + 1))
                raise ArgumentError.new('Invalid number of arguments for block')
            end
            @sockets[socket] ||= {}
            @sockets[socket][:procs] ||= []
            @sockets[socket][:procs] << [data, block]
            sync
        end

        # socket:: socket to remove
        # Removes socket from list
        def remove(socket)
            raise UnknownSocket.new(socket) unless @sockets.has_key?(socket)
            @sockets.delete(socket)
            sync
        end
        
        # socket:: socket to add close action
        # data:: data to be passed to the block. NOTE: socket
        # will be prepended to argument list
        # block:: action to perform on socket close
        # Executes block when socket has been closed. Ideal
        # for reconnection needs
        def on_close(socket, *data, &block)
            raise UnknownSocket.new(socket) unless @sockets.has_key?(socket)
            raise ArgumentError.new('Block must be supplied') unless block_given?
            raise ArgumentError.new('Block must allow at least one argument') if block.arity == 0
            if(block.arity > 0 && block.arity != (data.size + 1))
                raise ArgumentError.new('Invalid number of arguments for block')
            end
            @sockets[socket][:closed] ||= []
            @sockets[socket][:closed] << [data, block]
        end
        
        # remove all sockets
        def clear
            @sockets.clear
            stop
        end

        # start spockets
        def start
            raise AlreadyRunning.new if @watcher.running?
            @watcher.start
        end

        # stop spockets
        def stop
            raise NotRunning.new unless @watcher.running?
            @watcher.stop
        end

        # currently watching sockets
        def running?
            !@watcher.nil? && @watcher.running?
        end
        
        # socket:: a socket
        # check if the given socket is being watched
        def include?(socket)
            @sockets.has_key?(socket)
        end
        
        alias :delete :remove
        
    end

end