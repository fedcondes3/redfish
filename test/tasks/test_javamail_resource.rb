require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestJavamailResource < Redfish::Tasks::BaseTaskTest
  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-javamail-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-javamail-resource'),
                                 equals(['--debug', 'true', '--enabled', 'true', '--description', 'Audit DB', '--mailhost', 'mail.example.com', '--mailuser', 'myUser', '--fromaddress', 'myUser@example.com', '--storeprotocol', 'imap', '--storeprotocolclass', 'com.sun.mail.imap.IMAPStore', '--transprotocol', 'smtp2', '--transprotocolclass', 'com.sun.mail.smtp.SMTPTransport2', 'myThing']),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context), equals('get'),
                                 equals(["#{property_prefix}deployment-order"]),
                                 equals(:terse => true, :echo => false)).
      returns("#{property_prefix}deployment-order=100\n")

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-javamail-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("myThing\n")

    expected_local_properties.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%W(#{property_prefix}property.*)), equals(:terse => true, :echo => false)).
      returns('')

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-javamail-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("myThing\n")

    values = expected_local_properties
    values['transport-protocol'] = 'imap_other'

    values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}transport-protocol=smtp2"]),
                                 equals(:terse => true, :echo => false))

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(%W(#{property_prefix}property.*)),
                                 equals(:terse => true, :echo => false)).
      returns("#{property_prefix}property.DeleteMe=X")

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(%W(#{property_prefix}property.DeleteMe)),
                                 equals(:terse => true, :echo => false)).
        returns("#{property_prefix}property.DeleteMe=X")
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(%W(#{property_prefix}property.DeleteMe=)),
                                 equals(:terse => true, :echo => false))

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_element_where_cache_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-javamail-resource'),
                                 equals( ['--debug', 'true', '--enabled', 'true', '--description', 'Audit DB', '--mailhost', 'mail.example.com', '--mailuser', 'myUser', '--fromaddress', 'myUser@example.com', '--storeprotocol', 'imap', '--storeprotocolclass', 'com.sun.mail.imap.IMAPStore', '--transprotocol', 'smtp2', '--transprotocolclass', 'com.sun.mail.smtp.SMTPTransport2', 'myThing']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values = expected_properties
    cache_values["#{property_prefix}transport-protocol"] = 'smtp3'

    t.context.cache_properties(cache_values)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}transport-protocol=smtp2"]),
                                 equals(:terse => true, :echo => false))

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)

    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present
    t = new_task

    t.context.cache_properties(expected_properties)

    t.options = resource_parameters

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)

    ensure_expected_cache_values(t)
  end

  def test_delete_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'myThing'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-javamail-resources'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'myThing'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-javamail-resources'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("myThing\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-javamail-resource'),
                                 equals(['myThing']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_present_and_element_not_present
    t = new_task

    t.context.cache_properties({})
    t.options = {'name' => 'myThing'}

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties)
    t.options = {'name' => 'myThing'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-javamail-resource'),
                                 equals(['myThing']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  protected

  def property_prefix
    'resources.mail-resource.myThing.'
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'host' => 'mail.example.com',
      'user' => 'myUser',
      'from' => 'myUser@example.com',
      'store-protocol' => 'imap',
      'store-protocol-class' => 'com.sun.mail.imap.IMAPStore',
      'transport-protocol' => 'smtp2',
      'transport-protocol-class' => 'com.sun.mail.smtp.SMTPTransport2',
      'enabled' => 'true',
      'debug' => 'true',
      'description' => 'Audit DB',
      'deployment-order' => '100'
    }
  end

  # Resource parameters
  def resource_parameters
    {
      'name' => 'myThing',
      'host' => 'mail.example.com',
      'user' => 'myUser',
      'from' => 'myUser@example.com',
      'store_protocol' => 'imap',
      'store_protocol_class' => 'com.sun.mail.imap.IMAPStore',
      'transport_protocol' => 'smtp2',
      'transport_protocol_class' => 'com.sun.mail.smtp.SMTPTransport2',
      'enabled' => 'true',
      'debug' => 'true',
      'description' => 'Audit DB',
      'deploymentorder' => 100
    }
  end
end