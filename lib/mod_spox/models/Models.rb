module ModSpox
    module Models
        def self.stub(sym)
            unless(self.const_defined?(sym))
                self::const_set(sym, Class::new do
                    end
                )
            end
        end

        def self.unstub(sym)
            self.send(:remove_const, sym) if self.const_defined?(sym)
        end
    end
end
# Quick loader for all models
Dir.new(File.dirname(__FILE__)).each do |f|
    require File.dirname(__FILE__) + '/' + f if f =~ /\.rb$/
end