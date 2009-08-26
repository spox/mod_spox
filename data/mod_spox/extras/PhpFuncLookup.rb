require 'cgi'
require 'open-uri'

# Inspired from an old plugin for the original mod_spox
# Original development: spox & Ryan "pizza_milkshake" Flynn
# Ported: 2008

class PhpFuncLookup < ModSpox::Plugin

    include Models

    def initialize(pipeline)
        super(pipeline)
        setup_setting
        @path = Setting.val(:phpfunc)[:directory]
        @trigger = Setting.val(:phpfunc)[:trigger]
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
        add_sig(:sig => 'pfunc (\S+)', :method => :phpfunc, :desc => 'Lookup PHP function', :params => [:name])
        add_sig(:sig => 'fetch php manual', :method => :fetch, :group => admin, :desc => 'Download and extract PHP manual')
        add_sig(:sig => 'pfunc trigger (\S+)', :method => :set_trigger, :group => admin, :desc => 'Set the trigger for auto-lookups', :params => [:trigger])
        add_sig(:sig => 'pfunc show trigger', :method => :show_trigger, :desc => 'Show current trigger')
        add_sig(:sig => 'pfunc (add|remove) (\S+)', :method => :set_channels, :group => admin, :desc => 'Add or remove channels from auto-lookups', :params => [:action, :channel])
        add_sig(:sig => 'pfunc show channels', :method => :list_channels, :desc => 'Show channels with auto lookup enabled')
        Helpers.load_message(:incoming, :Privmsg)
        @pipeline.hook(self, :listen, ModSpox::Messages::Incoming::Privmsg)
        populate_classes
    end
        
    def phpfunc(m, params)
        name = params[:name].downcase
        Logger.info "phpfunc name=#{name}"
        if name =~ /^\S+$/ && name =~ /\*/
            parse_wildcard(m, name) 
        elsif name =~ /^\$/
            parse_predefined(m, name)
        elsif name =~ /^\S+$/ && filename = find_control_file(name)
            parse_control(m, name, filename)
        elsif name =~ /^\S+$/ && filename = find_function_file(name)
            parse_function(m, name, filename) 
        elsif @ops.has_key?(name)
            parse_operator(m, name) 
        end
    end
    
    def fetch(m, params)
        reply m.replyto, "Fetching PHP manual (This could take a few minutes)"
        fetch_manual(m)
    end
    
    def listen(m)
        if(m.target.is_a?(Channel) && Setting.val(:phpfunc)[:channels].include?(m.target.pk))
            if m.message =~ /^#{Regexp.escape(@trigger)}(\S+)$/
                phpfunc(m, {:name => $1})
            end
        end
    end
    
    def set_trigger(message, params)
        vals = Setting.val(:phpfunc)
        vals[:trigger] = params[:trigger]
        Setting.filter(:name => 'phpfunc').first.value = vals
        @trigger = params[:trigger]
        reply message.replyto, "PHP function lookup trigger set to: #{params[:trigger]}"
    end
    
    def set_channels(message, params)
        channel = Channel.filter(:name => params[:channel]).first
        if(channel)
            vals = Setting.val(:phpfunc)
            if(params[:action] == 'add')
                vals[:channels] << channel.pk unless Setting.val(:phpfunc)[:channels].include?(channel.pk)
                reply message.replyto, "Channel \2#{params[:channel]}\2 added to PHP auto lookup"
            else
                vals[:channels].delete(channel.pk) if Setting.val(:phpfunc)[:channels].include?(channel.pk)
                reply message.replyto, "Channel \2#{params[:channel]}\2 has been removed from PHP auto lookup"
            end
            Setting.filter(:name => 'phpfunc').first.value = vals
        else
            reply message.replyto, "Error: No record of channel #{params[:channel]}"
        end
    end
    
    def list_channels(message, params)
        if(Setting.val(:phpfunc)[:channels].size > 0)
            chans = []
            Setting.val(:phpfunc)[:channels].each do |id|
                chans << Channel[id].name
            end
            reply message.replyto, "PHP auto lookup enabled channels: #{chans.join(', ')}"
        else
            reply message.replyto, 'No channels currently enabled for PHP auto lookup'
        end
    end
    
    def show_trigger(message, p)
        reply message.replyto, "PHP auto lookup trigger: \2#{Setting.val(:phpfunc)[:trigger]}\2"
    end
    
    private

    def find_function_file(name)
        Dir.new(@manual).each do |filename|
            return filename if filename.downcase == "function.#{name.gsub(/(_|->)/, '-').downcase}.html"
        end
        return nil
    end
    
    def find_control_file(name)
        Dir.new(@manual).each do |filename|
            return filename if filename.downcase == "control-structures.#{name}.html"
        end
        return nil
    end

    def fetch_manual(message=nil, params=nil)
        Thread.new do
            Logger.info 'Fetching PHP manual from http://us.php.net'
            open("#{@path}/manual.tar.gz", 'w').write(open('http://us.php.net/distributions/manual/php_manual_en.tar.gz').read)
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
            s.value = {:directory => Config.val(:plugin_directory) + '/php', :trigger => '@', :channels => []}
        end
        unless(File.directory?(Setting.val(:phpfunc)[:directory]))
            FileUtils.mkdir_p(Setting.val(:phpfunc)[:directory])
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
        pattern = name.gsub(/\*/, '.*?').gsub(/_/, '-')
        Dir.open(@manual).each do |file|
            if(file =~ /^(function\.#{pattern})\.html/)
                match = $1
                if(match =~ /^function\.(.+?)\-/)
                    if(@classlist.include?($1.downcase))
                        match.gsub!(/[-]/, '_')
                        match.sub!(/_/, '->')
                    else
                        match.gsub!(/[-]/, '_')
                    end
                end
                match.gsub!(/^function\./, '')
                matches << match unless match.empty?
            end
        end
        matches.sort!
        output = matches.size > 20 ? ["Lots of matching functions. Truncating list to 20 results."] : []
        if(matches.empty?)
            output = "\2Error:\2 No matches found"
        else
            output << "Matches against term: \2#{name}:\2"
            output << matches.values_at(0..19).join(', ')
        end
        reply m.replyto, output
    end
    
    def parse_function(m, name, filename)
        page = File.open("#{@manual}/#{filename}", 'r').readlines.join('')
        page.gsub!(/[\r\n]/, '')
        versions = page =~ /<p class="verinfo">(.+?)<\/p>/i ? $1 : '(UNKNOWN)'
        proto = page =~ /<div class="methodsynopsis dc-description">(.+?)<\/div>/i ? $1 : name
        desc = page =~ /<p class="(para rdfs-comment|simpara)">(.+?)<\/p>/i ? $2.strip : '(UNKNOWN)'
        versions = CGI::unescapeHTML(versions)
        proto = CGI::unescapeHTML(proto.gsub(/<.+?>/, ' ').gsub(/[\s]+/, ' '))
        desc = CGI::unescapeHTML(desc.gsub(/<.+?>/, ' ').gsub(/[\s]+/, ' '))
        output = [versions]
        output << "\2#{proto}\2"
        output << Helpers.convert_entities(desc)
        output << "http://www.php.net/manual/en/#{filename.gsub(/\.html$/, '.php')}"
        reply m.replyto, output
    end

    def parse_operator(m, name)
        Logger.info "parse_operator name=#{name}"
        name.downcase!
        type, title, ejemplo = @ops[name]
        if(title.is_a?(Array))
            output = ["\2#{name}\2 is the \2#{title.join("\2 or \2")}\2 operator"]
            if(ejemplo.is_a?(Array))
                (0..(ejemplo.size - 1)).each do |i|
                    output << "\2Example (#{type[i]}):\2 #{ejemplo[i]}"
                end
            elsif(!ejemplo.nil?)
                output << "\2Example (#{type}):\2 #{ejemplo}"
            end
            type.each do |t|
                output << "http://php.net/manual/en/language.operators.#{t}.php"
            end
        else
            output = ["\2#{name}\2 is the \2#{title}\2 operator"]
            output << "\2Example usage:\2 #{ejemplo}" unless ejemplo.nil? || ejemplo.empty?
            output << "http://php.net/manual/en/language.operators.#{type}.php"
        end
        reply m.replyto, output
    end
    
    def parse_control(m, name, filename)
        page = File.open("#{@manual}/#{filename}", 'r').readlines.join('')
        page.gsub!(/[\r\n]/, '')
        con = page =~ /<h2 class="title"><i>([^<]+)</ ? $1 : '(UNKNOWN)'
        par = page =~ /^.+?<p class="para">(.+?)<div/ ? $1.strip : '(UNKNOWN)'
        Logger.info("Match: #{par}")
        par = par.gsub(/<.+?>/, ' ').gsub(/\s{2,}/, ' ')
        par.gsub!(/\.[^\.]+:$/, '.')
        #par.slice!(0..199) if par.size > 200
        output = ["\2Control structure: #{con}\2"]
        output << par
        output << "http://www.php.net/manual/en/#{filename.gsub(/\.html$/, '.php')}"
        reply m.replyto, output
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