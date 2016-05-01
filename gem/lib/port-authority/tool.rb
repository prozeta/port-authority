module PortAuthority
  class Tool
    def initialize
      self.optparse
      @ARGS = ARGV
      self.run
    end
  end
end
