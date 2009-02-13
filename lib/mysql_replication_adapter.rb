# we put this here, so that applications that have this plugin installed will still function
# even if they are not using our connection adapter.  The adapter itself will be dynamically loaded 
# when it is requested, as per active record adapter convention.
# That way applications written to use the adapter will still function without the use of the adapter, 
# allowing them for instance to turn it off in production by simply changing the adapter name 
# back to 'mysql'.
require 'active_record'
module ActiveRecord
  class Base
    class << self
      VALID_FIND_OPTIONS << :use_slave
    end
  end
end

#puts "------ here!!! --------"
require 'rails/version'
if Rails::VERSION::MAJOR < 2
  unless defined?(RAILS_CONNECTION_ADAPTERS) && RAILS_CONNECTION_ADAPTERS.include?("mysql_replication")
#    require 'active_record' unless defined?(RAILS_CONNECTION_ADAPTERS)
    require 'active_record/connection_adapters/mysql_replication_adapter'
    RAILS_CONNECTION_ADAPTERS << "mysql_replication"
  end
else
end

