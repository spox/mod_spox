require 'actionpool'

module Spockets
  class Watcher

    # :sockets:: socket list
    # :clean:: clean UTF8 strings or provide block to run on every read string
    # :pool:: ActionPool to use
    # Creates a new watcher for sockets
    def initialize(args={})
      raise ArgumentError.new('Expecting argument hash') unless args.is_a?(Hash)
      raise ArgumentError.new('Missing required argument :sockets') unless args[:sockets] && args[:sockets].is_a?(Hash)
      @sockets = args[:sockets]
      @runner = nil
      @clean = args[:clean] && (args[:clean].is_a?(Proc) || args[:clean].is_a?(TrueClass)) ? args[:clean] : nil
      @pool = args[:pool] && args[:pool].is_a?(ActionPool::Pool) ? args[:pool] : ActionPool::Pool.new
      if(@clean.is_a?(TrueClass))
        require 'iconv'
        @ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
      else
        @ic = nil
      end
      @stop = true
    end

    # start the watcher
    def start
      if(@sockets.size < 0)
        raise 'No sockets available for listening'
      elsif(!@runner.nil? && @runner.alive?)
        raise AlreadyRunning.new
      else
        @stop = false
        @runner = Thread.new{watch}
      end
    end

    # stop the watcher
    def stop
      if(@runner.nil? && @stop)
        raise NotRunning.new
      elsif(@runner.nil? || !@runner.alive?)
        @stop = true
        @runner = nil
      else
        @stop = true
        if(@runner)
          @runner.raise Resync.new if @runner.alive? && @runner.stop?
          @runner.join(0.05) if @runner
          @runner.kill if @runner && @runner.alive?
        end
        @runner = nil
      end
      nil
    end

    # is the watcher running?
    def running?
      !@stop
    end
    
    # clean incoming strings
    def clean?
      @clean
    end

    # Ensure all sockets are being listened to
    def sync
      raise NotRunning.new if @runner.nil?
      @runner.raise Resync.new
    end
    
    private

    # Watch the sockets and send strings for processing
    def watch
      until(@stop)
        begin
          resultset = Kernel.select(@sockets.keys, nil, nil, nil)
          for sock in resultset[0]
            string = sock.gets
            if(sock.closed? || string.nil?)
              if(@sockets[sock][:closed])
                @sockets[sock][:closed].each do |pr|
                  pr[1].call(*([sock]+pr[0]))
                end
              end
              @sockets.delete(sock)
            else
              string = clean? ? do_clean(string) : string
              process(string.dup, sock)
            end
          end
        rescue Resync
          # break select and relisten #
        end
      end
      @runner = nil
    end

    # string:: String from socket
    # sock:: Socket string originated from
    def process(string, sock)
      @sockets[sock][:procs].each do |pr|
        @pool.process do
          pr[1].call(*([string]+pr[0]))
        end
      end
    end

    # string:: String to be cleaned
    # Applies clean block to string
    def do_clean(string)
      unless(@ic.nil?)
        return untaint(string)
      else
        return @clean.call(string)
      end
    end

    # s:: string
    # Attempt to clean up string
    def untaint(s)
      @ic.iconv(s + ' ')[0..-2]
    end
  end
end