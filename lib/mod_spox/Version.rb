module ModSpox
    @botversion='0.3.2'
    @botcodename='potato cannon'
    @verbosity = 0
    @mod_spox_path = nil
    @daemon_bot = false
    @logto = nil
    @loglevel = :fatal
    @jdbc = false
    class << self
        attr_reader :botversion, :botcodename
        attr_accessor :verbosity, :mod_spox_path, :daemon_bot, :logto, :loglevel, :jdbc
    end
end