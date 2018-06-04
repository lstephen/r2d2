$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "r2d2"

require "minitest/autorun"
require "timecop"

begin
  require "pry-byebug"
rescue LoadError
  # Ignore, byebug is not installed for older ruby versions
end

>>>>>>> ruby-1.8.7
