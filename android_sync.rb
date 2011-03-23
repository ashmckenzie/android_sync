#!/usr/bin/env ruby

require 'rubygems'
require 'trollop'

require File.dirname(__FILE__) + '/lib/android_sync'

opts = Trollop::options do
  opt :help, 'Help', :short => 'h'
  opt :destination, "The destination root directory", :short => 'd', :type => String, :required => true
  opt :config, "Config file to read", :short => 'c', :type => String, :default => AndroidSync::DEFAULT_CONFIG
end

as = AndroidSync.new(opts)
as.run