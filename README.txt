MysqlReplicationAdapter
=======================

MysqlReplicationAdapter is an ActiveRecord database adapter that is designed to help applications connect to a single write master database and several read-only slave databases in a MySQL master-slave replication setup. This should allow much easier scaling of read volume by allowing read-only queries to be directed to a slave, leaving the master more room to breathe. 

Configuration
================
1. Install the plugin. 
-------------------
Download from Rubyforge via the bug patch.

2. Edit your environment.rb (ONLY FOR RAILS 1).
-------------------
Because of the way that Rails 1 loads database adapters, you must force it to load the new adapter.  You have to add this ABOVE the initializer block.  As follows:

$:.unshift File.join(File.dirname(__FILE__), '../vendor/plugins/mysql_replication_adapter/lib')
require 'mysql_replication_adapter'
...
Rails::Initializer.run do |config|


3. Add slaves to your database.yml.
-------------------
Slaves are configured on a by-environment basis, so pick any of your existing environments (development, production, etc.). Change the "driver" entry to "mysql_replication". Then, add a clones section like the one seen below.

development:
  host: masterdb
  port: 3306
  username: writeuser
  password: yourwritepassword
  database: yourapp_development
  slaves:
    - host: slavedb1
      port: 3306
      username: user
      password: yourpassword
      database: database
    - host: slavedb2
      port: 3306
      username: user
      password: yourpassword
      database: database

And so on. Add as many slaves as you'd like. There are no built-in limits.

And that's it. It's configured now. 

Usage
================
There are a number of ways to make use of the MysqlReplicationAdapter's slave-balancing capabilities. The simplest way is to pass a new option to ActiveRecord::Base#find. The option is called :use_slave, and it should => true when you want to send the query to a slave. For instance:

class Author < ActiveRecord::Base; end;

Author.find(:all, :use_slave => true)

This will choose a random slave and send it the query.

The other way to slave balance a query is to use block syntax. The ActiveRecord::Base#connection object now has a method called load_balance_query that requires a block. It will select a slave connection behind the scenes, and then any read queries you execute will be sent to that database for the duration of the block. For example:

ActiveRecord::Base.connection.load_balance_query do
  Author.find(:all) # will be load balanced, even though not specified to find
end

Note: if you use the block syntax and cause a write query to be generated somehow, then you will receive an exception. The adapter explicitly stops you from writing to any database but the master.

Another set of methods that can take advantage of the slave balancing is the calculations. For instance:

Author.count(:age, :use_slave => true)

Finally, I'm sure there are those of you saying, "But I use find_by_sql and that doesn't take an options hash!" Well, good news! There is now an optional second parameter to find_by_sql. If you pass true as that second parameter, it will select a random database and load balance that individual query. Snazzy! Example:

Author.find_by_sql("SELECT * FROM authors WHERE name = 'bryan';", true) # will be load balanced

Limitations
================
- MysqlReplicationAdapter has no idea of slave database currency. That is, if for some reason your slave dbs are way behind, and you send a query to a slave database, you could get back some out of date data. It's up to you to deal with this. My suggestion is to only load balance queries that you know you can get out-of-date data from and not be hurt. So, stick to authenticating people against the master database.

- MysqlReplicationAdapter doesn't do any sort of clever load balancing, it just selects a random slave from its set of slaves.

- MysqlReplicationAdapter doesn't partition your writes across multiple databases, and it isn't going to.
