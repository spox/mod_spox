require 'cgi'

# Inspired from an old plugin for the original mod_spox
# Original development: spox & Ryan "pizza_milkshake" Flynn
# Ported: 2008

class PhpFuncLookup < ModSpox::Plugin

    include Models

    def initialize(pipeline)
        super(pipeline)
        setup_setting
        @path = Setting[:phpfunc][:directory]
        @trigger = Setting[:phpfunc][:trigger]
        @manual = "#{@path}/html"
        @classlist = []
        fetch_manual unless File.exists?("#{@path}/manual.tar.gz")
        @ops = {
            "-"     => [ "arithmetic",  "Subtraction or Negation",      "3 - 2 == 1" ],
            "+"     => [ "arithmetic",  "Addition",                     "3 + 2 == 5" ],
            "*"     => [ "arithmetic",  "Multiplication",               "3 * 2 == 6" ],
            "/"     => [ "arithmetic",  "Division",                     "3 / 2 == 1.5" ],
            "%"     => [ "arithmetic",  "Modulus",                      "3 % 2 == 1" ],
            "="     => [ "assignment",  "Assignment",                   "$foo = 1; -> $foo == 1" ],
            "&"     => [
                        [ "bitwise", "references" ],
                        [ "Bitwise And", "Reference" ],
                        [ "0x3 & 0x1 -> 1",  "$foo=1; $bar=&$foo; $bar++; -> $foo == 2" ]
                       ],
            "|"     => [ "bitwise",     "Bitwise Or",                   "" ],
            "^"     => [ "bitwise",     "Bitwise Xor",                  "" ],
            "~"     => [ "bitwise",     "Bitwise Not",                  "" ],
            "<<"    => [ "bitwise",     "Bitwise Shift left",           "" ],
            ">>"    => [ "bitwise",     "Bitwise Shift right",          "" ],
            "=="    => [ "comparison",  "Equal",                        "" ],
            "==="   => [ "comparison",  "Identical",                    "" ],
            "!="    => [ "comparison",  "Not Equal",                    "" ],
            "<>"    => [ "comparison",  "Not Equal",                    "" ],
            "!=="   => [ "comparison",  "Not Identical",                "" ],
            "<"     => [ "comparison",  "Less Than",                    "" ],
            ">"     => [ "comparison",  "Greater Than",                 "" ],
            "<="    => [ "comparison",  "Less Than Or Equal To",        "" ],
            ">="    => [ "comparison",  "Greater Than Or Equal To",     "" ],
            "@"     => [ "errorcontrol","Error Control",                "" ],
            "`"     => [ "execution",   "Execution",                    "" ],
            "++"    => [ "increment",   "Pre- or Post-Increment",       "" ],
            "--"    => [ "increment",   "Pre- or Post-Decrement",       "" ],
            "and"   => [ "logical",     "And",                          "" ],
            "or"    => [ "logical",     "Or",                           "" ],
            "xor"   => [ "logical",     "Xor",                          "" ],
            "!"     => [ "logical",     "Not",                          "" ],
            "&&"    => [ "logical",     "And",                          "" ],
            "||"    => [ "logical",     "Or",                           "" ],
            "."     => [ "string",      "Concatenation",                "" ],
            ".="    => [ "string",      "Concatenation Assignment",     "" ],
            "instanceof" => [ "type",   "Instance Of",                  "" ],
            "new"   => [ "",            "New Object",                   "" ],
            "+="    => [ "assignment",  "Addition Assignment",          "" ],
            "-="    => [ "assignment",  "Subtraction Assignment",       "" ],
            "/="    => [ "assignment",  "Division Assignment",          "" ],
            "*="    => [ "assignment",  "Multiplication Assignment",    "" ],
            "%="    => [ "assignment",  "Modulus Assignment",           "" ],
            "->"    => [ "?",           "Object member accessor thingy","" ],
        }
        admin = Group.filter(:name => 'admin').first
        Signature.find_or_create(:signature => 'pfunc (\S+)', :plugin => name, :method => 'phpfunc', :description => 'Lookup PHP function').params = [:name]
        Signature.find_or_create(:signature => 'fetch php manual', :plugin => name, :method => 'fetch', :group_id => admin.pk,
            :description => 'Download and extract PHP manual')
        Signature.find_or_create(:signature => 'pfunc trigger (\S+)', :plugin => name, :method => 'set_trigger', :group_id => admin.pk,
            :description => 'Set the trigger for auto-lookups').params = [:trigger]
        Signature.find_or_create(:signature => 'pfunc show trigger', :plugin => name, :method => 'show_trigger', :description => 'Show current trigger')
        Signature.find_or_create(:signature => 'pfunc (add|remove) (\S+)', :plugin => name, :method => 'set_channels', :group_id => admin.pk,
            :description => 'Add or remove channels from auto-lookups').params = [:action, :channel]
        Signature.find_or_create(:signature => 'pfunc show channels', :plugin => name, :method => 'list_channels', :description => 'Show channels with auto lookup enabled')
        @pipeline.hook(self, :listen, :Incoming_Privmsg)
        populate_classes
    end
        
    def phpfunc(m, params)
        name = params[:name].downcase
        Logger.info "phpfunc name=#{name}"
        if name =~ /^\S+$/ && name =~ /\*/
            parse_wildcard(m, name) 
        elsif name =~ /^\$/
            parse_predefined(m, name) 
        elsif name =~ /^\S+$/ && filename = find_file(name)
            parse_function(m, name, filename) 
        elsif @ops.has_key?(name)
            parse_operator(m, name) 
        end
    end
    
    def fetch(m, params)
        reply m.replyto, "Fetching PHP manual (This could take a few minutes)"
        fetch_manual
    end
    
    def listen(m)
        if(m.target.is_a?(Channel) && Setting[:phpfunc][:channels].include?(m.target.pk))
            if m.message =~ /^#{Regexp.escape(@trigger)}(\S+)$/
                phpfunc(m, {:name => $1})
            end
        end
    end
    
    def set_trigger(message, params)
        vals = Setting[:phpfunc]
        vals[:trigger] = params[:trigger]
        Setting.filter(:name => 'phpfunc').first.value = vals
        @trigger = params[:trigger]
        reply message.replyto, "PHP function lookup trigger set to: #{params[:trigger]}"
    end
    
    def set_channels(message, params)
        channel = Channel.filter(:name => params[:channel]).first
        if(channel)
            vals = Setting[:phpfunc]
            if(params[:action] == 'add')
                vals[:channels] << channel.pk unless Setting[:phpfunc][:channels].include?(channel.pk)
                reply message.replyto, "Channel \2#{params[:channel]}\2 added to PHP auto lookup"
            else
                vals[:channels].delete(channel.pk) if Setting[:phpfunc][:channels].include?(channel.pk)
                reply message.replyto, "Channel \2#{params[:channel]}\2 has been removed from PHP auto lookup"
            end
            Setting.filter(:name => 'phpfunc').first.value = vals
        else
            reply message.replyto, "Error: No record of channel #{params[:channel]}"
        end
    end
    
    def list_channels(message, params)
        if(Setting[:phpfunc][:channels].size > 0)
            chans = []
            Setting[:phpfunc][:channels].each do |id|
                chans << Channel[id].name
            end
            reply message.replyto, "PHP auto lookup enabled channels: #{chans.join(', ')}"
        else
            reply message.replyto, 'No channels currently enabled for PHP auto lookup'
        end
    end
    
    def show_trigger(message, p)
        reply message.replyto, "PHP auto lookup trigger: \2#{Setting[:phpfunc][:trigger]}\2"
    end
    
    private

    def find_file(name)
        Dir.new(@manual).each do |filename|
            return filename if filename.downcase == "function.#{name.gsub(/(_|->)/, '-').downcase}.html"
        end
        return nil
    end

    def fetch_manual(message=nil, params=nil)
        Thread.new do
            manual_site = 'http://us.php.net/'
            Logger.info "Fetching PHP manual from #{manual_site}"
            connection = Net::HTTP.new("us.php.net", 80)
            File.open("#{@path}/manual.tar.gz", 'w'){ |manual|
                connection.get('/distributions/manual/php_manual_en.tar.gz', nil){ |line|
                    manual.write(line)
                }
            }
            Dir.chdir(@path)
            Helpers.safe_exec("tar -xzf #{@path}/manual.tar.gz", 60)
            Logger.info "PHP manual fetching complete."
            reply message.replyto, "PHP manual fetch is now complete" unless message.nil?
        end
    end

    def setup_setting
        s = Setting.filter(:name => 'phpfunc').first
        unless(s)
            s = Setting.find_or_create(:name => 'phpfunc')
            s.value = {:directory => Config[:plugin_directory] + '/php', :trigger => '@', :channels => []}
        end
        unless(File.directory?(Setting[:phpfunc][:directory]))
            FileUtils.mkdir_p(Setting[:phpfunc][:directory]) 
        end
    end
    
    def parse_predefined(m, name)
        name.upcase!
        page = File.open("#{@manual}/language.variables.predefined.html").readlines.join(' ').gsub(/[\n\r]/, '')
        if page =~ /<dt>\s*<span class="term"><a href="reserved\.variables\.html.+? class="link">#{name.gsub(/\$/, '\$')}<\/a><\/span>\s*<dd>\s*<span class="simpara">(.+?)<\/span>/
            desc = $1
            desc.gsub!(/[\r\n]/, ' ')
            desc.gsub!(/<.+?>/, ' ')
            desc = CGI::unescapeHTML(desc.gsub(/\s+/, ' '))
            output = ["\2PHP Superglobal\2"]
            output << "\2#{name}:\2 #{desc}"
        else
            output = "No superglobal found matching: #{name}"
        end
        reply m.replyto, output
    end
    
    def parse_wildcard(m, name)
        matches = []
        pattern = name.gsub(/\*/, '.*?')
        Dir.open(@manual).each do |file|
            if(file =~ /^(.+?#{pattern}.+?)\.html/)
                match = $1
                if(match =~ /^function\.(.+?)\-/)
                    if(@classlist.include?($1.downcase))
                        match.gsub!(/[-]/, '_')
                        match.sub!(/_/, '->')
                    else
                        match.gsub!(/[-]/, '_')
                    end
                    match.gsub!(/^function\./, '')
                else
                    match = nil
                end
                matches << match unless match.nil?
            end
        end
        matches.sort!
        output = matches.size > 20 ? ["Lots of matching functions. Truncating list to 20 results."] : []
        if(matches.empty?)
            output = "\2Error:\2 No matches found"
        else
            output << matches.values_at(0..19).join(', ')
        end
        reply m.replyto, output
    end
    
    def parse_function(m, name, filename)
        page = File.open("#{@manual}/#{filename}", 'r').readlines.join('')
        page.gsub!(/[\r\n]/, '')
        versions = page =~ /<p class="verinfo">(.+?)<\/p>/i ? $1 : '(UNKNOWN)'
        proto = page =~ /<div class="methodsynopsis dc-description">(.+?)<\/div>/i ? $1 : name
        desc = page =~ /<p class="refpurpose dc-title">.+? — (.+?)<\/p>/i ? $1 : '(UNKNOWN)'
        versions = CGI::unescapeHTML(versions)
        proto = CGI::unescapeHTML(proto.gsub(/<.+?>/, ' ').gsub(/[\s]+/, ' '))
        desc = CGI::unescapeHTML(desc.gsub(/<.+?>/, ' ').gsub(/[\s]+/, ' '))
        output = [versions]
        output << "\2#{proto}\2"
        output << desc
        output << "http://www.php.net/manual/en/#{filename.gsub(/\.html$/, '.php')}"
        reply m.replyto, output
    end

    def parse_operator(m, name)
        Logger.info "parse_operator name=#{name}"
        name.downcase!
        type, title, ejemplo = @ops[name]
        output = ["\2#{name}\2 is the \2#{title.to_a.join("\2 or \2")}\2 operator"]
        type.to_a.each do |t|
            output << "http://php.net/manual/en/language.operators.#{t}.php"
        end
    end
    
    def populate_classes
        if(@classlist.empty?)
            Dir.open(@manual).each do |file|
                if(file =~ /^class\.(.+?)\.html/)
                    @classlist << $1
                end
            end
            @classlist.uniq!
        end
    end
    
end