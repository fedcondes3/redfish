#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestDomain < Redfish::Tasks::BaseTaskTest
  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    assert_equal t.to_s, "domain[name=domain1 dir=#{test_domains_dir}/domain1]"
  end

  def test_create_when_not_present
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor,
                                                    :domains_directory => test_domains_dir,
                                                    :system_user => 'bob',
                                                    :system_group => 'bobgrp'))

    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/lib")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/lib/ext")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/bin")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/config")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/config/redfish.password")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/bin/asadmin")).returns('')

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-domain'),
                                 equals(%W(--checkports=false --savelogin=false --savemasterpassword=false --domaindir #{test_domains_dir} --template payara --keytooloptions CN=MyHost.example.com --domainproperties domain.adminPort=4848:domain.instancePort=1:domain.jmxPort=1:http.ssl.port=1:java.debugger.port=1:jms.port=1:orb.listener.port=1:orb.mutualauth.port=1:orb.ssl.port=1:osgi.shell.telnet.port=1 domain1)),
                                 equals({})).
      returns('')

    t.template = 'payara'
    t.common_name = 'MyHost.example.com'

    props = {}

    %w(domain.adminPort domain.instancePort domain.jmxPort http.ssl.port java.debugger.port jms.port orb.listener.port orb.mutualauth.port orb.ssl.port osgi.shell.telnet.port).each do |key|
      props[key] = 1
      props[key] = t.context.domain_admin_port if key == 'domain.adminPort'
    end
    t.properties = props
    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)

    assert File.directory?("#{test_domains_dir}/domain1/bin")
    assert File.directory?("#{test_domains_dir}/domain1/lib")
    assert File.directory?("#{test_domains_dir}/domain1/lib/ext")
    assert File.file?("#{test_domains_dir}/domain1/bin/asadmin")

    cmd_script = IO.read("#{test_domains_dir}/domain1/bin/asadmin")
    assert_equal cmd_script, <<-CMD
#!/bin/sh

/opt/payara-4.1.151/glassfish/bin/asadmin --terse=false --echo=true --user admin --passwordfile=#{t.context.domain_password_file_location} --port 4848 "$@"
    CMD
  end

  def test_create_with_most_common_options
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-domain'),
                                 equals(%W(--checkports=false --savelogin=false --savemasterpassword=false --domaindir #{test_domains_dir} --domainproperties domain.adminPort=4848 domain1)),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_with_mismatched_aadmin_port
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    t.properties = {'domain.adminPort' => t.context.domain_admin_port + 1}
    begin
      t.perform_action(:create)
      fail
    rescue Exception => e
      assert_equal e.to_s, "Domain property 'domain.adminPort' is set to '4849' which does not match context configuration value of '4848'"
    end

    ensure_task_not_updated_by_last_action(t)
  end

  def test_create_with_unknown_property
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    t.properties = {'x' => 'y'}
    begin
      t.perform_action(:create)
      fail
    rescue Exception => e
      assert_equal e.to_s, "Unknown domain property 'x' specified."
    end

    ensure_task_not_updated_by_last_action(t)
  end

  def test_create_when_present
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    FileUtils.mkdir_p(t.context.domain_directory)

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_destroy_when_not_present
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_destroy_when_present
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-domain'),
                                 equals(%W(--domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    FileUtils.mkdir_p(t.context.domain_directory)

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end

  def test_start_when_not_running
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-domains'),
                                 equals(%W(--domaindir #{test_domains_dir})),
                                 equals({:terse => true, :echo => false})).
      returns('domain1 not running')
    executor.expects(:exec).with(equals(t.context),
                                 equals('start-domain'),
                                 equals(%W(--domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    t.perform_action(:start)

    ensure_task_updated_by_last_action(t)
  end

  def test_start_when_running
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-domains'),
                                 equals(%W(--domaindir #{test_domains_dir})),
                                 equals({:terse => true, :echo => false})).
      returns('domain1 running')

    t.perform_action(:start)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_start_when_running_but_requires_restart
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-domains'),
                                 equals(%W(--domaindir #{test_domains_dir})),
                                 equals({:terse => true, :echo => false})).
      returns('domain1 running, restart required to apply configuration changes')

    t.perform_action(:start)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_stop_when_running
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-domains'),
                                 equals(%W(--domaindir #{test_domains_dir})),
                                 equals({:terse => true, :echo => false})).
      returns('domain1 running')
    executor.expects(:exec).with(equals(t.context),
                                 equals('stop-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    t.perform_action(:stop)

    ensure_task_updated_by_last_action(t)
  end

  def test_stop_when_not_running
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-domains'),
                                 equals(%W(--domaindir #{test_domains_dir})),
                                 equals({:terse => true, :echo => false})).
      returns('domain1 not running')

    t.perform_action(:stop)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_restart
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('restart-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    # Mock out the ensure active
    t.expects(:do_ensure_active)

    t.perform_action(:restart)

    ensure_task_updated_by_last_action(t)
  end

  def test_restart_if_required
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('_get-restart-required'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("true\n")
    executor.expects(:exec).with(equals(t.context),
                                 equals('restart-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    # Mock out the ensure active
    t.expects(:do_ensure_active)

    t.perform_action(:restart_if_required)

    assert !t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_restart_if_required_using_context
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('restart-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    t.context.require_restart!

    # Mock out the ensure active
    t.expects(:do_ensure_active)

    t.perform_action(:restart_if_required)

    assert !t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_restart_if_required_using_context_only
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('restart-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    t.context.require_restart!

    # Mock out the ensure active
    t.expects(:do_ensure_active)

    t.context_only = true

    t.perform_action(:restart_if_required)

    assert !t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_restart_if_required_using_context_only_not_required
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    t.context_only = true

    t.perform_action(:restart_if_required)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_restart_if_required_when_not_required
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('_get-restart-required'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("false\n")

    t.perform_action(:restart_if_required)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_ensure_active
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   false,
                                   'admin',
                                   'password',
                                   :domains_directory => test_domains_dir)
    t = new_task_with_context(context)

    %w(/ /management/domain/nodes /management/domain/applications).each do |path|
      t.expects(:is_url_responding_with_ok?).with(equals("http://127.0.0.1:4848#{path}"),
                                                  equals('admin'),
                                                  equals('password')).
        returns(true)
    end

    t.perform_action(:ensure_active)

    ensure_task_updated_by_last_action(t)
  end

  def test_ensure_active_in_secure_domain
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   1234,
                                   true,
                                   'admin1',
                                   'password2',
                                   :domains_directory => test_domains_dir)
    t = new_task_with_context(context)

    %w(/ /management/domain/nodes /management/domain/applications).each do |path|
      t.expects(:is_url_responding_with_ok?).with(equals("https://127.0.0.1:1234#{path}"),
                                                  equals('admin1'),
                                                  equals('password2')).
        returns(true)
    end

    t.perform_action(:ensure_active)

    ensure_task_updated_by_last_action(t)
  end

  def test_ensure_active_when_not_active
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   false,
                                   'admin',
                                   'password',
                                   :domains_directory => test_domains_dir)
    t = new_task_with_context(context)

    s = sequence('main')

    t.expects(:is_url_responding_with_ok?).with(equals('http://127.0.0.1:4848/'),
                                                equals('admin'),
                                                equals('password')).
      returns(false).
      in_sequence(s)

    Kernel.expects(:sleep).with(equals(1)).in_sequence(s)

    %w(/ /management/domain/nodes /management/domain/applications).each do |path|
      t.expects(:is_url_responding_with_ok?).with(equals("http://127.0.0.1:4848#{path}"),
                                                  equals('admin'),
                                                  equals('password')).
        returns(true).
        in_sequence(s)
    end

    t.max_mx_wait_time = 1
    t.perform_action(:ensure_active)

    ensure_task_updated_by_last_action(t)
  end

  def test_ensure_active_when_not_active_in_time
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   false,
                                   'admin',
                                   'password',
                                   :domains_directory => test_domains_dir)
    t = new_task_with_context(context)

    s = sequence('main')

    t.expects(:is_url_responding_with_ok?).with(equals('http://127.0.0.1:4848/'),
                                                equals('admin'),
                                                equals('password')).
      returns(false).
      in_sequence(s)

    Kernel.expects(:sleep).with(equals(1)).in_sequence(s)

    t.expects(:is_url_responding_with_ok?).with(equals('http://127.0.0.1:4848/'),
                                                equals('admin'),
                                                equals('password')).
      returns(false).
      in_sequence(s)


    t.max_mx_wait_time = 1

    begin
      t.perform_action(:ensure_active)
    rescue => e
      assert_equal e.message, 'GlassFish failed to become operational'
    end

    ensure_task_not_updated_by_last_action(t)
  end

  def test_enable_secure_admin
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   true,
                                   'admin',
                                   'password',
                                   :domains_directory => test_domains_dir,
                                   :system_user => 'bob',
                                   :system_group => 'bobgrp')
    t = new_task_with_context(context)

    t.context.cache_properties({})

    executor.expects(:exec).with(equals(t.context),
                                 equals('enable-secure-admin'),
                                 equals([]),
                                 equals({:secure => false})).
      returns('')

    executor.expects(:exec).with(equals(t.context),
                                 equals('restart-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({:secure => false})).
      returns('')

    # Mock out the ensure active
    t.expects(:do_ensure_active)

    FileUtils.mkdir_p "#{test_domains_dir}/domain1/config"
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/config/secure.marker")).returns('')

    t.perform_action(:enable_secure_admin)

    assert File.exist?("#{test_domains_dir}/domain1/config/secure.marker")

    # Cache should have been destroyed when action completed
    assert !context.property_cache?

    ensure_task_updated_by_last_action(t)
  end

  def test_enable_secure_admin_when_already_secure
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   true,
                                   'admin',
                                   'password',
                                   :domains_directory => test_domains_dir)
    t = new_task_with_context(context)

    t.context.cache_properties({})
    FileUtils.mkdir_p "#{test_domains_dir}/domain1/config"
    FileUtils.touch "#{test_domains_dir}/domain1/config/secure.marker"

    t.perform_action(:enable_secure_admin)

    # Cache should not have been destroyed as action did not cause update
    assert context.property_cache?

    ensure_task_not_updated_by_last_action(t)
  end
end
