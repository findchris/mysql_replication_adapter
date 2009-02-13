require 'test/unit'
require "rubygems"
require 'rails/version'
puts "--- here --"
#require File.dirname(__FILE__) + '/../lib/mysql_replication_adapter'
#require File.dirname(__FILE__) + '/../lib/active_record/connection_adapters/mysql_replication_adapter'
$:.unshift(File.dirname(__FILE__) + "/../lib")
#puts $:
require 'mysql_replication_adapter'
require 'active_record/connection_adapters/mysql_replication_adapter'
