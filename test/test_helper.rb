$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "r2d2"

require "minitest/autorun"

require "timecop"

def require_if_present(dep)
  require dep
rescue LoadError
  # Ignore
end

require_if_present "pry-byebug"

