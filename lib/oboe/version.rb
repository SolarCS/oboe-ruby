# Copyright (c) 2013 AppNeta, Inc.
# All rights reserved.

module Oboe
  ##
  # The current version of the gem.  Used mainly by
  # oboe.gemspec during gem build process
  module Version
    MAJOR = 2
    MINOR = 7
    PATCH = 1
    BUILD = 7

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end
