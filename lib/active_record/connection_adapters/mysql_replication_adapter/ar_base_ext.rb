require 'active_record/connection_adapters/mysql_adapter'

module ActiveRecord

  class Base
    class << self
      
      # Establishes a connection to the database that's used by all Active Record objects.
      def mysql_replication_connection(config) # :nodoc:
        config = config.symbolize_keys
        host     = config[:host]
        port     = config[:port]
        socket   = config[:socket]
        username = config[:username] ? config[:username].to_s : 'root'
        password = config[:password].to_s

        if config.has_key?(:database)
          database = config[:database]
        else
          raise ArgumentError, "No database specified. Missing argument: database."
        end

        # Require the MySQL driver and define Mysql::Result.all_hashes
        unless defined? Mysql
          begin
            require_library_or_gem('mysql')
          rescue LoadError
            $stderr.puts '!!! The bundled mysql.rb driver has been removed from Rails 2.2. Please install the mysql gem and try again: gem install mysql.'
            raise
          end
        end
        MysqlCompat.define_all_hashes_method!

        mysql = Mysql.init
        mysql.ssl_set(config[:sslkey], config[:sslcert], config[:sslca], config[:sslcapath], config[:sslcipher]) if config[:sslca] || config[:sslkey]

        ConnectionAdapters::MysqlReplicationAdapter.new(mysql, logger, [host, username, password, database, port, socket], config)
      end

      # make our standard checks.  First, ensure they asked for a slave.  Then, make sure our connection
      # is in fact of the right type.  Finally, check to see if we're in a transaction.  If we are,
      # use the master to ensure accuracy.
      # Note that though the code is cleaner, this will increase call times by 2x over the 
      # boolean check below.  
      # From preliminary tests, for a simple query, I see about a 10% overhead to invoking the 
      # load_balance_query, and another 5% overhead to invoking this run_on method with the yield.
      def run_on_db(use_slave = nil)
#        logger.debug("checking conn.  use_slave? #{use_slave} in trans? #{Thread.current['open_transactions']}") if logger && logger.debug
        if (use_slave && 
            connection.is_a?(ConnectionAdapters::MysqlReplicationAdapter) && 
            (Thread.current['open_transactions'] || 0) == 0)

          connection.load_balance_query { yield }
        else
          yield
        end
      end

      def slave_valid(use_slave = nil)
#        logger.debug("checking conn.  use_slave? #{use_slave} in trans? #{Thread.current['open_transactions']}") if logger && logger.debug
        use_slave && 
          connection.is_a?(ConnectionAdapters::MysqlReplicationAdapter) && 
          (Thread.current['open_transactions'] || 0) == 0
      end

      def get_use_slave(arg)
        if arg && arg.is_a?(Hash) then return arg[:use_slave]
        else return arg
        end
      end

      alias_method :old_find_every, :find_every
      # Override the standard find to check for the :use_slave option. When specified, the
      # resulting query will be sent to a slave machine.
      def find_every(options)
#        run_on_db(options[:use_slave]) do
#          old_find_every(options)
#        end
        if slave_valid(options[:use_slave]) 
          connection.load_balance_query { old_find_every(options) }
        else
          old_find_every(options)
        end
      end
      
      alias_method :old_find_by_sql, :find_by_sql
      # Override find_by_sql so that you can tell it to selectively use a slave machine
      def find_by_sql(sql, use_slave = false)
        use_slave = get_use_slave(use_slave)
#        run_on_db(use_slave) do
#          old_find_by_sql sql
#        end
        if slave_valid(use_slave)
          connection.load_balance_query { old_find_by_sql sql }
        else
          old_find_by_sql sql
        end
      end

      alias_method :old_count_by_sql, :count_by_sql
      def count_by_sql(sql, use_slave = false)
        use_slave = get_use_slave(use_slave)
#        run_on_db(use_slave) do
#          old_count_by_sql sql
#        end
        if slave_valid(use_slave)
          connection.load_balance_query { old_count_by_sql sql }
        else
          old_count_by_sql sql
        end
      end

      
      alias_method :old_calculate, :calculate
      def calculate(operation, column_name, options ={})
        use_slave = options.delete(:use_slave)
#        run_on_db(use_slave) do
#          old_calculate(operation, column_name, options)
#        end
        if slave_valid(use_slave)
          connection.load_balance_query { old_calculate(operation, column_name, options) }
        else
          old_calculate(operation, column_name, options)
        end
      end

    end
    
  end
end
