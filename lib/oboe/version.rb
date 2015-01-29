# Copyright (c) 2013 AppNeta, Inc.
# All rights reserved.

module Oboe
  ##
  # The current version of the gem.  Used mainly by
  # oboe.gemspec during gem build process
  module Version
    MAJOR = 2
    MINOR = 7
    PATCH = 9
    BUILD = 6

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end
