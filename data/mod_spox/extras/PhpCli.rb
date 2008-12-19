# IMPORTANT NOTE: This plugin will only function if the PHP executable can be located
class PhpCli < ModSpox::Plugin

    include Models
    include Messages::Outgoing

    def initialize(pipeline)
        super(pipeline)
        @path = Config[:plugin_directory] + '/phpcli'
        @botini = @path + '/bot.ini'
        unless(File.directory?(@path))
            FileUtils.mkdir_p(@path)
        end
        result = Helpers.safe_exec('which php')
        raise NoInterpreter.new if result.empty?
        unless File.exists?(@botini)
            ini = File.new(@botini, 'w')
            ini.write($ini)
            ini.close
        end
        php = Group.find_or_create(:name => 'php')
        admin = Group.filter(:name => 'admin').first
        Signature.find_or_create(:signature => 'php (on|off)', :plugin => name, :method => 'set_channel', :group_id => admin.pk,
            :description => 'Add or remove channel from allowing PHP command').params = [:action]
        Signature.find_or_create(:signature => 'php (?!on|off)(.+)', :plugin => name, :method => 'execute_php', :group_id => php.pk,
            :description => 'Execute PHP code').params = [:code]
        @channels = Setting.filter(:name => 'phpcli').first
        @channels = @channels.nil? ? [] : @channels.value
    end

    def set_channel(message, params)
        return unless message.is_public?
        if(params[:action] == 'on')
            unless(@channels.include?(message.target.pk))
                @channels << message.target.pk
                tmp = Setting.find_or_create(:name => 'phpcli')
                tmp.value = @channels
                tmp.save
            end
            reply message.replyto, 'PHP command now active'
        else
            unless(@channels.include?(message.target.pk))
                reply message.replyto, 'PHP command is not currently active in this channel'
            else
                @channels.delete(message.target.pk)
                tmp = Setting.find_or_create(:name => 'phpcli')
                tmp.value = @channels
                tmp.save
                reply message.replyto, 'PHP command is now disabled'
            end
        end
    end

    def execute_php(message, params)
        return unless @channels.include?(message.target.pk)
        filepath = @path + "/#{rand(99999)}.bot.php"
        file = File.open(filepath, 'w')
        file.write("<? $_SERVER = $_ENV = array(); #{params[:code]} ?>")
        file.close
        begin
            output = Helpers.safe_exec("php -c #{@path}/bot.ini -d max_execution_time=10 #{filepath} 2>&1 | head -n 4")
            if(output =~ /^sh: line [0-9]+:(.*)$/)
                output = $1
            end
            if(output =~ /^(Fatal error|Warning|Parse error): (.+?) in .*? on line [0-9]+[\n|\r]*(.*)$/)
                warning = $2
                type = $1
                output = $3
            end
            if(output.length > 300)
                reply message.replyto, "#{message.source.nick}: Your result has been truncated. Don't print so much."
                output = output.slice(0, 300)
            end
            if(!warning.nil?)
                reply message.replyto, "PHP #{type}: "+warning
            end
            if(warning.nil? || type !~ /(Fatal|Parse)/)
                reply message.replyto, "Result: "+output
            end
            File.delete(filepath)
        rescue Timeout::Error => boom
            reply message.replyto, "\2Error:\2 Timeout reached: #{boom}"
        rescue Object => boom
            reply message.replyto, "\2Error:\2 Script execution terminated. (#{boom})"
            File.delete(filepath)
        end
    end

    class NoInterpreter < Exceptions::BotException
    end

end

$ini = <<EOF
[PHP]
engine = On
zend.ze1_compatibility_mode = Off
short_open_tag = On
asp_tags = Off
precision    =  12
y2k_compliance = On
output_buffering = Off
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func=
serialize_precision = 100
allow_call_time_pass_reference = On
safe_mode = On
safe_mode_gid = On
safe_mode_include_dir = /tmp/mod_spox/php
safe_mode_exec_dir = /tmp/mod_spox/php
safe_mode_allowed_env_vars = PHP_
safe_mode_protected_env_vars = LD_LIBRARY_PATH
open_basedir = /tmp/mod_spox
disable_functions = fscanf fputs chown chmod copy delete fflush file flock ftell glob link fseek lstat move_uploaded_file rename realpath set_file_buffer touch fprintf chgrp fgetss readfile dio_close dio_fnctl dio_open dio_read dio_seek dio_stat dio_tcsetattr dio_truncate dio_write chdir chroot dir closedir getcwd opendir readdir rewinddir scandir posix_kill posix_access posix_ctermid posix_get_last_error posix_getcwd posix_getegid posix_geteuid posix_getgid posix_getgrgid posix_getgrnam posix_getgroups posix_getlogin posix_getpgid posix_getpgrp posix_getpid posix_getppid posix_getpwnam posix_getpwuid posix_getwuid posix_getrlimit posix_getsid posix_getuid posix_isatty posix_mkfifo posix_mknod posix_setegid posix_setgid posix_setpgid posix_setsid posix_setuid posix_strerror posix_times posix_ttyname posix_uname expect_expectl expect_popen sleep time_sleep_until usleep pfsockopen fsockopen openlog debugger_on proc_open pclose popen fsockopen fread set_time_limit ini_set ini_alter ini_restore exec system passthru proc_close proc_nice proc_open proc_terminiate shell_exec sleep usleep pcntl_fork pcntl_exec pcntl_alarm pcntl_getpriority pcntl_setpriority pcntl_waitpid pcntl_wexitstatus pcntl_wifexited pcntl_wifsignaled pcntl_wifstopped pcntl_wstopsig pcntl_wtermsig readline_add_history readline_callback_handler_install readline_callback_handler_remove readline_callback_read_char readline_clear_history readline_completion_function readline_info readline_list_history readline_on_new_line readline_read_history readline_redisplay readline_write_history readline dl set_include_path set_magic_quotes_runtime file_put_contents fwrite fputs copy fputcsv tmpfile symlink tempnam mysql_connect unlink putenv ftp_connect socket_create socket_create socket_close socket_accept socket_bind socket_close socket_connect socket_create_listen socket_create_pair socket_get_option socket_listen socket_read socket_recv socket_select socket_send socket_sendto shmop_close shmop_open shmop_delete shmop_read shmop_size shmop_write msg_get_queue msg_receive msg_remove_queue msg_send msg_set_queue msg_stat_queue msg_acquire sem_aquire sem_release sem_get sem_remove mail time_nanosleep usleep include include_once require require_once ftp_alloc ftp_cdup ftp_chdir ftp_chmod ftp_close ftp_connect ftp_delete ftp_exec ftp_fget ftp_fput ftp_get ftp_get_option ftp_login ftp_mdtm ftp_mkdir ftp_nb_continue ftp_nb_fget ftp_nb_fput ftp_nb_get ftp_nb_put
disable_classes = dir
expose_php = On
max_execution_time = 10
max_input_time = 20
memory_limit = 4M
error_reporting  =  E_ALL & ~E_NOTICE & ~E_STRICT
display_errors = On
display_startup_errors = Off
log_errors = Off
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
track_errors = Off
variables_order = "EGPCS"
register_globals = Off
register_long_arrays = On
register_argc_argv = On
post_max_size = 8M
magic_quotes_gpc = On
magic_quotes_runtime = Off
magic_quotes_sybase = Off
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
include_path = ".:/usr/share/php"
doc_root = /tmp/mod_spox/php
user_dir = /tmp/mod_spox/php
enable_dl = On
file_uploads = Off
allow_url_fopen = Off
default_socket_timeout = 10
define_syslog_variables  = Off
sendmail_path = /dev/null
[Sockets]
sockets.use_system_read = On
EOF