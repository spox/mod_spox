module Handlers
  class Raw < Handler
    def types_process
      :UNKNOWN
    end
    def process(string)
      m = mk_struct(string)
      m.type = :raw
      m
    end
  end
end
