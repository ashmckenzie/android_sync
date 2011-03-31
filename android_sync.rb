#!/usr/bin/env ruby

require 'rubygems'
require 'trollop'

require File.dirname(__FILE__) + '/lib/android_sync'

opts = Trollop::options do
  opt :help, 'Help', :short => 'h'
  opt :destination, "The destination root directory", :short => 'd', :type => String, :required => true
  opt :config, "Config file to read", :short => 'c', :type => String, :default => AndroidSync::DEFAULT_CONFIG
  opt :forreal, "Do the sync for real", :short => 'p', :default => AndroidSync::DEFAULT_FORREAL
  opt :quiet, "Quiet output", :default => AndroidSync::DEFAULT_QUIET
  opt :debug, "Debug output", :default => AndroidSync::DEFAULT_DEBUG
end

as = AndroidSync.new(opts)
as.run
