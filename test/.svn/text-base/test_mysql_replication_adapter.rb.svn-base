require File.dirname(__FILE__) + '/test_helper.rb'
require 'optparse'


class Person < ActiveRecord::Base

end

class TestMysqlReplicationAdapter < Test::Unit::TestCase

  @@user = "root"
  @@password = nil
  @@host = "localhost"
  @@options = nil


  def self.parse_opts
    @@options = OptionParser.new do |o|
      o.banner = "test arguments.  Add -- prior to arguments- for instance"
      o.banner << "\n  ruby #{__FILE__} -- --user=foo"
      o.on("-u", "--user=USER", "db user to connect with") do |arg|
        @@user = arg
      end
      o.on("-p", "--password=PASSWORD", "db password to connect with") do |arg|
        @@password = arg
      end
      o.on("-H", "--host=HOST", "db host to connect with") do |arg|
        @@host = arg
      end
      o.on('-h', '--help', 'Display this help.'){puts o; exit}
    end
    @@options.parse!
  end

  def setup
    self.class.parse_opts unless @@options

    @dbs = [ 'mysql_repl_test_master', 'mysql_repl_test_slave_1', 'mysql_repl_test_slave_2' ]

    begin
      @adapter = get_adapter
      ActiveRecord::Base.connection = @adapter
    rescue => e
      # this is weak.  I'd like a way to fail fast.  But I don't know how.
      raise "Could not connect to database: #{e}\n#{@@options}"
    end

    @dbs.each do |db|
      table = "#{db}.people"
      @adapter.drop_table table rescue nil
      @adapter.create_table table do |t|
        t.column :name, :string
      end
    end

  end
  
  def teardown
    return unless @adapter
    @dbs.each do |db|
      @adapter.drop_table "#{db}.people" rescue nil
    end
#    @adapter.drop_table :people
  end
  
  def get_adapter
    ActiveRecord::Base.mysql_replication_connection(
      {"host" => @@host,
        "username" => @@user, 
        "password" => @@password,
        "database" => "mysql_repl_test_master",
        "retries" => 2,
        "slaves" => [
          {"host" => @@host,
            "username" => @@user,
            "password" => @@password,
            "database" => "mysql_repl_test_slave_1"
          },
          {"host" => @@host,
            "username" => @@user,
            "password" => @@password,
            "database" => "mysql_repl_test_slave_2"
          }
        ]
      }
    )
  end
    
  def test_insert
    assert_not_nil Person.create(:name => "blah")
  end
  
  def test_find
    Person.create(:name => "blah")
    p = Person.find(1)
    assert_not_nil p
    assert_equal p.id, 1
    assert_equal Person.find_by_id(1, :use_slave => false).id, 1
    assert_nil Person.find_by_id(1, :use_slave => true)
  end
  
  def test_find_by_sql
    Person.create(:name => "blah")
    p = Person.find_by_sql("select * from people")
    assert_not_nil p
    assert_equal 1, p.length
    assert_equal 1, p.first.id
    assert_equal 0, Person.find_by_sql("select * from people", true).length
    assert_equal 1, Person.find_by_sql("select * from people", false).length
    assert_equal 0, Person.find_by_sql("select * from people", :use_slave => true).length
    assert_equal 1, Person.find_by_sql("select * from people", :use_slave => false).length
    assert_equal 0, Person.find_by_sql(["select * from people where id = ?", 1], :use_slave => true).length
  end

  def test_count_by_sql
    Person.create(:name => "blah")
    assert_equal 1, Person.count_by_sql("select count(*) from people")
    assert_equal 0, Person.count_by_sql("select count(*) from people", true)
    assert_equal 1, Person.count_by_sql("select count(*) from people", false)
    assert_equal 0, Person.count_by_sql("select count(*) from people", :use_slave => true)
    assert_equal 1, Person.count_by_sql("select count(*) from people", :use_slave => false)
    assert_equal 0, Person.count_by_sql(["select count(*) from people where id = ?", 1], :use_slave => true)
  end


  def test_calculate
    Person.create(:name => "blah")
    assert_equal 1, Person.count
    assert_equal 1, Person.count(:use_slave => false)
    assert_equal 0, Person.count(:use_slave => true)
  end

  def test_update
    Person.create(:name => "blah")
    p = Person.find_by_id(1)
    p.name = "blarg"
    p.save
    assert_equal 1, Person.count_by_sql(["select count(*) from people where name = ?", 'blarg'])
  end

  def test_transaction
    Person.transaction do
      Person.create(:name => "blah")
      p = Person.find_by_id(1, :use_slave => true)
      assert_not_nil p
      assert_equal 1, p.id
    end
  end
end
