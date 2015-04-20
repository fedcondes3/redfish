require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestJdbcConnectionPool < Redfish::TestCase
  def test_no_cache_and_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'pool_name' => 'APool',
                 'datasourceclassname' => 'net.sourceforge.jtds.jdbcx.JtdsDataSource',
                 'restype' => 'javax.sql.DataSource',
                 'validationmethod' => 'auto-commit',
                 'isconnectvalidatereq' => 'true',
                 'ping' => 'true',
                 'description' => 'Audit Connection Pool',
                 'deploymentorder' => 100,
                 'properties' =>
                   {
                     'Instance' => 'MSSQLSERVER',
                     'ServerName' => 'db.example.com',
                     'User' => 'sa',
                     'Password' => 'password',
                     'PortNumber' => '1234',
                     'DatabaseName' => 'MYDB'
                   }
    }

    executor.expects(:exec).with(equals(t.context), equals('list-jdbc-connection-pools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jdbc-connection-pool'),
                                 equals(['--datasourceclassname=net.sourceforge.jtds.jdbcx.JtdsDataSource', '--initsql=', '--sqltracelisteners=', '--driverclassname=', '--validationclassname=', '--validationtable=', '--steadypoolsize=8', '--maxpoolsize=32', '--maxwait=60000', '--poolresize=2', '--idletimeout=300', '--validateatmostonceperiod=0', '--leaktimeout=0', '--statementleaktimeout=0', '--creationretryattempts=0', '--creationretryinterval=10', '--statementtimeout=-1', '--maxconnectionusagecount=0', '--statementcachesize=0', '--isisolationguaranteed=true', '--isconnectvalidatereq=true', '--failconnection=false', '--allownoncomponentcallers=false', '--nontransactionalconnections=false', '--statementleakreclaim=false', '--leakreclaim=false', '--lazyconnectionenlistment=false', '--lazyconnectionassociation=false', '--associatewiththread=false', '--matchconnections=false', '--ping=true', '--pooling=true', '--wrapjdbcobjects=true', '--restype=javax.sql.DataSource', '--isolationlevel=', '--validationmethod=auto-commit', '--property', 'Instance=MSSQLSERVER:ServerName=db\\.example\\.com:User=sa:Password=password:PortNumber=1234:DatabaseName=MYDB', '--description', 'Audit Connection Pool', 'APool']),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context), equals('get'),
                                 equals(['resources.jdbc-connection-pool.APool.deployment-order']),
                                 equals(:terse => true, :echo => false)).
      returns("resources.jdbc-connection-pool.APool.deployment-order=100\n")

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, true
  end

  def test_no_cache_and_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'pool_name' => 'APool',
                 'datasourceclassname' => 'net.sourceforge.jtds.jdbcx.JtdsDataSource',
                 'restype' => 'javax.sql.DataSource',
                 'validationmethod' => 'auto-commit',
                 'isconnectvalidatereq' => 'true',
                 'ping' => 'true',
                 'description' => 'Audit Connection Pool',
                 'deploymentorder' => 100,
                 'properties' =>
                   {
                     'Instance' => 'MSSQLSERVER',
                     'ServerName' => 'db.example.com',
                     'User' => 'sa',
                     'Password' => 'password',
                     'PortNumber' => '1234',
                     'DatabaseName' => 'MYDB'
                   }}

    executor.expects(:exec).with(equals(t.context), equals('list-jdbc-connection-pools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("APool\n")

    {
      'description' => 'Audit Connection Pool',
      'datasource-classname' => 'net.sourceforge.jtds.jdbcx.JtdsDataSource',
      'init-sql' => '',
      'sql-trace-listeners' => '',
      'driver-classname' => '',
      'validation-classname' => '',
      'validation-table-name' => '',
      'steady-pool-size' => '8',
      'max-pool-size' => '32',
      'max-wait-time-in-millis' => '60000',
      'pool-resize-quantity' => '2',
      'idle-timeout-in-seconds' => '300',
      'validate-atmost-once-period-in-seconds' => '0',
      'connection-leak-timeout-in-seconds' => '0',
      'statement-leak-timeout-in-seconds' => '0',
      'connection-creation-retry-attempts' => '0',
      'connection-creation-retry-interval-in-seconds' => '10',
      'statement-timeout-in-seconds' => '-1',
      'max-connection-usage-count' => '0',
      'statement-cache-size' => '0',
      'is-isolation-level-guaranteed' => 'true',
      'is-connection-validation-required' => 'true',
      'fail-all-connections' => 'false',
      'allow-non-component-callers' => 'false',
      'non-transactional-connections' => 'false',
      'statement-leak-reclaim' => 'false',
      'connection-leak-reclaim' => 'false',
      'lazy-connection-enlistment' => 'false',
      'lazy-connection-association' => 'false',
      'associate-with-thread' => 'false',
      'match-connections' => 'false',
      'ping' => 'true',
      'pooling' => 'true',
      'wrap-jdbc-objects' => 'true',
      'res-type' => 'javax.sql.DataSource',
      'transaction-isolation-level' => '',
      'connection-validation-method' => 'auto-commit',
      'property.Instance' => 'MSSQLSERVER',
      'property.ServerName' => 'db.example.com',
      'property.User' => 'sa',
      'property.Password' => 'password',
      'property.PortNumber' => '1234',
      'property.DatabaseName' => 'MYDB',
      'deployment-order' => '100'
    }.each_pair do |k, v|

      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["resources.jdbc-connection-pool.APool.#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("resources.jdbc-connection-pool.APool.#{k}=#{v}\n")
    end

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, false
  end

  def test_no_cache_and_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'pool_name' => 'APool',
                 'datasourceclassname' => 'net.sourceforge.jtds.jdbcx.JtdsDataSource',
                 'restype' => 'javax.sql.DataSource',
                 'validationmethod' => 'auto-commit',
                 'isconnectvalidatereq' => 'true',
                 'ping' => 'true',
                 'description' => 'Audit Connection Pool',
                 'deploymentorder' => 100,
                 'properties' =>
                   {
                     'Instance' => 'MSSQLSERVER',
                     'ServerName' => 'db.example.com',
                     'User' => 'sa',
                     'Password' => 'password',
                     'PortNumber' => '1234',
                     'DatabaseName' => 'MYDB'
                   }}

    executor.expects(:exec).with(equals(t.context), equals('list-jdbc-connection-pools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("APool\n")

    {
      'description' => 'X',
      'datasource-classname' => 'net.sourceforge.jtds.jdbcx.JtdsDataSource',
      'init-sql' => '',
      'sql-trace-listeners' => '',
      'driver-classname' => '',
      'validation-classname' => '',
      'validation-table-name' => '',
      'steady-pool-size' => '8',
      'max-pool-size' => '32',
      'max-wait-time-in-millis' => '60000',
      'pool-resize-quantity' => '2',
      'idle-timeout-in-seconds' => '300',
      'validate-atmost-once-period-in-seconds' => '0',
      'connection-leak-timeout-in-seconds' => '0',
      'statement-leak-timeout-in-seconds' => '0',
      'connection-creation-retry-attempts' => '0',
      'connection-creation-retry-interval-in-seconds' => '10',
      'statement-timeout-in-seconds' => '-1',
      'max-connection-usage-count' => '0',
      'statement-cache-size' => '0',
      'is-isolation-level-guaranteed' => 'true',
      'is-connection-validation-required' => 'true',
      'fail-all-connections' => 'false',
      'allow-non-component-callers' => 'false',
      'non-transactional-connections' => 'false',
      'statement-leak-reclaim' => 'false',
      'connection-leak-reclaim' => 'false',
      'lazy-connection-enlistment' => 'false',
      'lazy-connection-association' => 'false',
      'associate-with-thread' => 'false',
      'match-connections' => 'false',
      'ping' => 'false',
      'pooling' => 'true',
      'wrap-jdbc-objects' => 'true',
      'res-type' => 'javax.sql.DataSource',
      'transaction-isolation-level' => '',
      'connection-validation-method' => 'auto-commit',
      'property.Instance' => 'MSSQLSERVER',
      'property.ServerName' => 'db.example.com',
      'property.User' => 'sa',
      'property.Password' => 'secret',
      'property.PortNumber' => '1234',
      'property.DatabaseName' => 'MYDB',
      'deployment-order' => '99'
    }.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["resources.jdbc-connection-pool.APool.#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("resources.jdbc-connection-pool.APool.#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-connection-pool.APool.property.Password=password']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-connection-pool.APool.deployment-order=100']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-connection-pool.APool.description=Audit Connection Pool']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-connection-pool.APool.ping=true']),
                                 equals(:terse => true, :echo => false))

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, true
  end

  def test_cache_and_no_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})

    t.options = {'pool_name' => 'APool',
                 'datasourceclassname' => 'net.sourceforge.jtds.jdbcx.JtdsDataSource',
                 'restype' => 'javax.sql.DataSource',
                 'validationmethod' => 'auto-commit',
                 'isconnectvalidatereq' => 'true',
                 'ping' => 'true',
                 'description' => 'Audit Connection Pool',
                 'deploymentorder' => 100,
                 'properties' =>
                   {
                     'Instance' => 'MSSQLSERVER',
                     'ServerName' => 'db.example.com',
                     'User' => 'sa',
                     'Password' => 'password',
                     'PortNumber' => '1234',
                     'DatabaseName' => 'MYDB'
                   }
    }

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jdbc-connection-pool'),
                                 equals(['--datasourceclassname=net.sourceforge.jtds.jdbcx.JtdsDataSource', '--initsql=', '--sqltracelisteners=', '--driverclassname=', '--validationclassname=', '--validationtable=', '--steadypoolsize=8', '--maxpoolsize=32', '--maxwait=60000', '--poolresize=2', '--idletimeout=300', '--validateatmostonceperiod=0', '--leaktimeout=0', '--statementleaktimeout=0', '--creationretryattempts=0', '--creationretryinterval=10', '--statementtimeout=-1', '--maxconnectionusagecount=0', '--statementcachesize=0', '--isisolationguaranteed=true', '--isconnectvalidatereq=true', '--failconnection=false', '--allownoncomponentcallers=false', '--nontransactionalconnections=false', '--statementleakreclaim=false', '--leakreclaim=false', '--lazyconnectionenlistment=false', '--lazyconnectionassociation=false', '--associatewiththread=false', '--matchconnections=false', '--ping=true', '--pooling=true', '--wrapjdbcobjects=true', '--restype=javax.sql.DataSource', '--isolationlevel=', '--validationmethod=auto-commit', '--property', 'Instance=MSSQLSERVER:ServerName=db\\.example\\.com:User=sa:Password=password:PortNumber=1234:DatabaseName=MYDB', '--description', 'Audit Connection Pool', 'APool']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, true
    ensure_expected_cache_values(t)
  end

  def test_cache_and_present_but_modified
    cache_values = get_expected_cache_values

    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values['resources.jdbc-connection-pool.APool.ping'] = 'false'
    cache_values['resources.jdbc-connection-pool.APool.description'] = 'XXX'
    cache_values['resources.jdbc-connection-pool.APool.deployment-order'] = '101'
    cache_values['resources.jdbc-connection-pool.APool.property.Password'] = 'secret'

    t.context.cache_properties(cache_values)

    t.options = {'pool_name' => 'APool',
                 'datasourceclassname' => 'net.sourceforge.jtds.jdbcx.JtdsDataSource',
                 'restype' => 'javax.sql.DataSource',
                 'validationmethod' => 'auto-commit',
                 'isconnectvalidatereq' => 'true',
                 'ping' => 'true',
                 'description' => 'Audit Connection Pool',
                 'deploymentorder' => 100,
                 'properties' =>
                   {
                     'Instance' => 'MSSQLSERVER',
                     'ServerName' => 'db.example.com',
                     'User' => 'sa',
                     'Password' => 'password',
                     'PortNumber' => '1234',
                     'DatabaseName' => 'MYDB'
                   }}


    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-connection-pool.APool.property.Password=password']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-connection-pool.APool.deployment-order=100']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-connection-pool.APool.description=Audit Connection Pool']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-connection-pool.APool.ping=true']),
                                 equals(:terse => true, :echo => false))
    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, true

    ensure_expected_cache_values(t)
  end

  def test_cache_and_present
    cache_values = get_expected_cache_values

    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(cache_values)

    t.options = {'pool_name' => 'APool',
                 'datasourceclassname' => 'net.sourceforge.jtds.jdbcx.JtdsDataSource',
                 'restype' => 'javax.sql.DataSource',
                 'validationmethod' => 'auto-commit',
                 'isconnectvalidatereq' => 'true',
                 'ping' => 'true',
                 'description' => 'Audit Connection Pool',
                 'deploymentorder' => 100,
                 'properties' =>
                   {
                     'Instance' => 'MSSQLSERVER',
                     'ServerName' => 'db.example.com',
                     'User' => 'sa',
                     'Password' => 'password',
                     'PortNumber' => '1234',
                     'DatabaseName' => 'MYDB'
                   }}

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, false

    ensure_expected_cache_values(t)
  end

  def ensure_expected_cache_values(t)
    get_expected_cache_values.each_pair do |key, value|
      assert_equal t.context.property_cache[key], value, "Expected #{key}=#{value}"
    end
  end

  def get_expected_cache_values
    cache_values = {}

    {
      'description' => 'Audit Connection Pool',
      'datasource-classname' => 'net.sourceforge.jtds.jdbcx.JtdsDataSource',
      'init-sql' => '',
      'sql-trace-listeners' => '',
      'driver-classname' => '',
      'validation-classname' => '',
      'validation-table-name' => '',
      'steady-pool-size' => '8',
      'max-pool-size' => '32',
      'max-wait-time-in-millis' => '60000',
      'pool-resize-quantity' => '2',
      'idle-timeout-in-seconds' => '300',
      'validate-atmost-once-period-in-seconds' => '0',
      'connection-leak-timeout-in-seconds' => '0',
      'statement-leak-timeout-in-seconds' => '0',
      'connection-creation-retry-attempts' => '0',
      'connection-creation-retry-interval-in-seconds' => '10',
      'statement-timeout-in-seconds' => '-1',
      'max-connection-usage-count' => '0',
      'statement-cache-size' => '0',
      'is-isolation-level-guaranteed' => 'true',
      'is-connection-validation-required' => 'true',
      'fail-all-connections' => 'false',
      'allow-non-component-callers' => 'false',
      'non-transactional-connections' => 'false',
      'statement-leak-reclaim' => 'false',
      'connection-leak-reclaim' => 'false',
      'lazy-connection-enlistment' => 'false',
      'lazy-connection-association' => 'false',
      'associate-with-thread' => 'false',
      'match-connections' => 'false',
      'ping' => 'true',
      'pooling' => 'true',
      'wrap-jdbc-objects' => 'true',
      'res-type' => 'javax.sql.DataSource',
      'transaction-isolation-level' => '',
      'connection-validation-method' => 'auto-commit',
      'property.Instance' => 'MSSQLSERVER',
      'property.ServerName' => 'db.example.com',
      'property.User' => 'sa',
      'property.Password' => 'password',
      'property.PortNumber' => '1234',
      'property.DatabaseName' => 'MYDB',
      'deployment-order' => '100'
    }.each_pair do |k, v|
      cache_values["resources.jdbc-connection-pool.APool.#{k}"] = "#{v}"
    end
    cache_values
  end

  def new_task(executor)
    t = Redfish::Tasks::JdbcConnectionPool.new
    t.context = Redfish::Context.new(executor, '/opt/payara-4.1.151/', 'domain1', 4848, false, 'admin', nil)
    t
  end
end