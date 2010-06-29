require 'timeout'

module Splib

    @@processes = []
    @@owner ||= Thread.current
    Kernel.at_exit do
        if(Thread.current == @@owner)
            @@processes.each{|pro| Process.kill('KILL', pro.pid) }
        end
    end

    # Returns current array of running Processes
    def self.running_procs
        @@processes
    end
    # command:: command string to execute
    # timeout:: length of time to execute
    # maxbytes:: maximum number return bytes allowed
    # Execute system command. This is a wrapper method
    # that will redirect to the proper command
    def self.exec(*args)
        if(RUBY_PLATFORM == 'java')
            thread_exec(*args)
        else
            standard_exec(*args)
        end
    end
    
    # command:: command to execute
    # timeout:: maximum number of seconds to run
    # maxbytes:: maximum number of result bytes to accept
    # priority:: set priority of the process
    # Execute a system command (use with care)
    # This is the normal exec command that is used
    def self.standard_exec(command, timeout=10, maxbytes=500, priority=nil)
        timeout = timeout.to_i
        maxbytes = maxbytes.to_i
        priority = priority.to_i
        output = []
        pro = nil
        begin
            if(timeout > 0)
                Timeout::timeout(timeout) do
                    pro = IO.popen(command)
                    @@processes << pro
                    if(priority > 0)
                        Process.setpriority(Process::PRIO_PROCESS, pro.pid, priority)
                    end
                    until(pro.closed? || pro.eof?)
                        output << pro.getc.chr
                        if(maxbytes > 0 && output.size > maxbytes)
                            raise IOError.new("Maximum allowed output bytes exceeded. (#{maxbytes} bytes)")
                        end
                    end
                end
            else
                pro = IO.popen(command)
                @@processes << pro
                until(pro.closed? || pro.eof?)
                    output << pro.getc.chr
                    if(maxbytes > 0 && output.size > maxbytes)
                        raise IOError.new("Maximum allowed output bytes exceeded. (#{maxbytes} bytes)")
                    end
                end
            end
            output = output.join('')
        ensure
            Process.kill('KILL', pro.pid) if Process.waitpid2(pro.pid, Process::WNOHANG).nil? # make sure the process is dead
            @@processes.delete(pro)
        end
        return output
    end
    # Used for the thread_exec method to notify of completion
    class Complete < StandardError
    end

    # command:: command to execute
    # timeout:: maximum number of seconds to run
    # maxbytes:: maximum number of result bytes to accept
    # priority:: set priority of the process
    # Execute a system command (use with care)
    # This is the threaded exec command that is generally used
    # with JRuby. The regular timeout does not work when executing
    # a process, so we do it in a separate thread and sleep the main
    # thread until the timeout is reached.
    def self.thread_exec(command, timeout=10, maxbytes=500)
        timeout = timeout.to_i
        maxbytes = maxbytes.to_i
        priority = priority.to_i
        current = Thread.current
        output = []
        pro = nil
        thread = Thread.new do
            boom = Complete.new
            begin
                pro = IO.popen(command)
                @@processes << pro
                if(priority > 0)
                    Process.setpriority(Process::PRIO_PROCESS, pro.pid, priority)
                end
                until(pro.closed? || pro.eof?)
                    output << pro.getc.chr
                    if(maxbytes > 0 && output.size > maxbytes)
                        raise IOError.new("Maximum allowed output bytes exceeded. (#{maxbytes} bytes)")
                    end
                end
            rescue Exception => boom
                # just want it set
            end
            current.raise boom unless boom.is_a?(Timeout::Error)
        end
        begin
            begin
                if(timeout > 0)
                    thread.join(timeout)
                    thread.raise Timeout::Error.new
                    raise Timeout::Error.new
                else
                    thread.join
                end
                output.join('')
            rescue Complete
                # ignore this exception
            end
        ensure
            Process.kill('KILL', pro.pid) unless pro.nil?
            @@processes.delete(pro)
        end
        output.join('')
    end
end