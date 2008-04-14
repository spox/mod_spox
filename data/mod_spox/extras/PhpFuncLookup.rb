require 'cgi'

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
        Signature.find_or_create(:signature => 'pfunc (\S+)', :plugin => name, :method => 'pfunc', :description => 'Lookup PHP function').params = [:name]
        Signature.find_or_create(:signature => 'fetch php manual', :plugin => name, :method => 'fetch', :group_id => Group.filter(:name => 'admin').first.pk,
            :description => 'Download and extract PHP manual')
        @pipeline.hook(self, :listen, :Incoming_Privmsg)
    end
        
    def pfunc(m, params)
        name = params[:name].downcase
        Logger.log "pfunc name=#{name}"
        if name =~ /^\S+$/ && name =~ /\*/
            parse_wildcard(m, name) 
        elsif name =~ /^\$/
            parse_predefined(m, name) 
        elsif name =~ /^\S+$/ && File.exists?("#{@manual}/function.#{name.gsub(/_/, '-')}.html")
            parse_function(m, name) 
        elsif @ops.has_key?(name)
            parse_operator(m, name) 
        end
    end
    
    def fetch(m, params)
        reply m.replyto, "Fetching PHP manual (This could take a few minutes)"
        fetch_manual
    end
    
    def listen(m)
        if(m.target.is_a?(Channel) && m.target.name.downcase == '#php')
            if m.message =~ /^#{Regexp.escape(@trigger)}(\S+)$/
                pfunc(m, {:name => $1})
            end
        end
    end
    
    private

    def fetch_manual(message=nil, params=nil)
        Thread.new do
            manual_site = 'http://us.php.net/'
            Logger.log "Fetching PHP manual from #{manual_site}"
            connection = Net::HTTP.new("us.php.net", 80)
            File.open("#{@path}/manual.tar.gz", 'w'){ |manual|
                connection.get('/distributions/manual/php_manual_en.tar.gz', nil){ |line|
                    manual.write(line)
                }
            }
            Dir.chdir(@path)
            Helpers.safe_exec("tar -xzf #{@path}/manual.tar.gz", 60)
            Logger.log "PHP manual fetching complete."
            reply message.replyto, "PHP manual fetch is now complete" unless message.nil?
        end
    end

    def setup_setting
        Setting[:phpfunc] = {:directory => Config[:plugin_directory] + '/php', :trigger => '@' } if Setting[:phpfunc].nil?
        unless(File.directory?(Setting[:phpfunc][:directory]))
            FileUtils.mkdir_p(Setting[:phpfunc][:directory]) 
        end
    end
    
    def parse_predefined(m, name)
        name.upcase!
        page = File.open("#{@manual}/language.variables.predefined.html").readlines.join(' ').gsub(/[\n\r]/, '')
        debug page
        if page =~ /#{name.gsub(/\$/, '\$')}<\/A.+?&#13;(.+?)<CODE/
            desc = $1
            desc.gsub!(/\s+/, ' ')
            reply m.replyto, "\2PHP Superglobal\2"
            reply m.replyto, "\2#{name}:\2 #{desc}"
        else
            reply m.replyto, "No superglobal found matching: #{name}"
        end
    end
    
    def parse_wildcard(m, name)
        matches = []
        pattern = name.gsub(/\*/, '.*?')
        if(@classlist.empty?)
            Dir.open(@manual).each do |file|
                if(file =~ /^class\.(.+?)\.html/)
                    @classlist << $1
                end
            end
            @classlist.uniq!
        end
        Dir.open(@manual).each do |file|
            if(file =~ /^(.+?#{pattern}.+?)\.html/)
                match = $1
                if(match =~ /^function\.(.+?)\-/)
                    if(@classlist.include?($1.downcase))
                        match.gsub!(/[-]/, '->')
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
        reply m.replyto, "Lots of matching functions. Truncating list to 20 results."
        reply m.replyto, matches.values_at(0..19).join(', ')
    end
    
    def parse_function(m, name)
        page = File.open("#{@manual}/function.#{name.gsub(/_/, '-')}.html", 'r').readlines.join('')
        page.gsub!(/[\r\n]/, '')
        versions = page =~ /<p>[\s]+(\(.+?\))<\/p>/mi ? $1 : '(UNKNOWN)'
        proto = page =~ /<h2>Description<\/h2>(.+?)<br><\/br><p>/i ? $1 : name
        desc = page =~ /<\/p>#{name.gsub(/-/, '_')}&nbsp;--&nbsp;(.+?)<\/div><divclass=/i ? $1 : '(UNKNOWN)'
        versions = CGI::unescapeHTML(versions)
        proto = CGI::unescapeHTML(proto.gsub(/<.+?>/, ' ').gsub(/[\s]+/, ' '))
        desc = CGI::unescapeHTML(desc.gsub(/<.+?>/, ' ').gsub(/[\s]+/, ' '))
        reply m.replyto, versions
        reply m.replyto, "\2#{proto}\2"
        reply m.replyto, desc
        reply m.replyto, "http://www.php.net/#{name}"
    end

    def parse_operator(m, name)
        Logger.log "parse_operator name=#{name}"
        name.downcase!
        type, title, ejemplo = @ops[name]
        reply m.replyto, "\2#{name}\2 is the \2#{title.to_a.join("\2 or \2")}\2 operator"
        type.to_a.each do |t|
            reply m.replyto, "http://php.net/manual/en/language.operators.#{t}.php"
        end
    end
    
end