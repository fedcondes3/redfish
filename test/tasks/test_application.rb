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

class Redfish::Tasks::TestApplication < Redfish::Tasks::BaseTaskTest
  def setup
    super
    @location = @deployment_plan = nil
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    assert_equal t.to_s, 'application[MyApplication]'
  end

  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-applications'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('deploydir'),
                                 equals(['--name', 'MyApplication', '--enabled=true', '--force=true', '--type', 'war', '--contextroot=/myapp', '--generatermistubs=true', '--availabilityenabled=true', '--lbenabled=true', '--keepstate=true', '--verify=true', '--precompilejsp=true', '--asyncreplication=true', '--deploymentplan', "#{self.temp_dir}/myapp-plan.jar", '--deploymentorder', '100', '--property', 'java-web-start-enabled=false', "#{self.temp_dir}/myapp"]),
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

    executor.expects(:exec).with(equals(t.context), equals('list-applications'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("MyApplication <web>\n")
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%W(#{property_prefix}property.*)), equals(:terse => true, :echo => false)).
      returns('')

    expected_local_properties.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-applications'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("MyApplication     <web>\n")
    # Return a property that should be deleted
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%W(#{property_prefix}property.*)), equals(:terse => true, :echo => false)).
      returns("#{property_prefix}property.Blah=Y\n")

    values = expected_local_properties
    values['deployment-order'] = '101'
    values['enabled'] = 'false'

    values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}enabled=true"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}deployment-order=100"]),
                                 equals(:terse => true, :echo => false))

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(["#{property_prefix}property.Blah"]),
                                 equals(:terse => true, :echo => false)).
      returns("#{property_prefix}property.Blah=X\n")

    # This is the set to remove property that should not exist
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.Blah="]),
                                 equals(:terse => true, :echo => false)).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_element_where_cache_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('deploydir'),
                                 equals(['--name', 'MyApplication', '--enabled=true', '--force=true', '--type', 'war', '--contextroot=/myapp', '--generatermistubs=true', '--availabilityenabled=true', '--lbenabled=true', '--keepstate=true', '--verify=true', '--precompilejsp=true', '--asyncreplication=true', '--deploymentplan', "#{self.temp_dir}/myapp-plan.jar", '--deploymentorder', '100', '--property', 'java-web-start-enabled=false', "#{self.temp_dir}/myapp"]),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present_but_modified
    cache_values = expected_properties

    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values["#{property_prefix}enabled"] = 'false'
    cache_values["#{property_prefix}deployment-order"] = '101'

    # This property should be removed
    cache_values["#{property_prefix}property.Blah"] = 'X'

    t.context.cache_properties(cache_values)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.Blah="]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}deployment-order=100"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}enabled=true"]),
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

    t.options = {'name' => 'MyApplication'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-applications'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'MyApplication'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-applications'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("MyApplication     <web>\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('undeploy'),
                                 equals(['--cascade=false', 'MyApplication']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_present_and_element_not_present
    t = new_task

    t.context.cache_properties({})
    t.options = {'name' => 'MyApplication'}

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties)
    t.options = {'name' => 'MyApplication'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('undeploy'),
                                 equals(['--cascade=false', 'MyApplication']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  protected

  def property_prefix
    'applications.application.MyApplication.'
  end

  def location_as_dir
    unless @location
      @location = "#{self.temp_dir}/myapp"
      FileUtils.mkdir_p @location
      File.open("#{@location}/index.txt",'w') {|f| f << 'Hi' }
    end
    @location
  end

  def deployment_plan
    unless @deployment_plan
      @deployment_plan = "#{self.temp_dir}/myapp-plan.jar"
      File.open(@deployment_plan,'w') {|f| f << '' }
    end
    @deployment_plan
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'enabled' => 'true',
      'async-replication' => 'true',
      'availability-enabled' => 'true',
      'directory-deployed' => 'true',
      'context-root' => '/myapp',
      'location' => "file:#{self.location_as_dir}/",
      'property.defaultAppName' => 'MyApplication',
      'property.archiveType' => 'war',
      'property.appLocation' => "file:#{self.location_as_dir}/",
      'property.java-web-start-enabled' => 'false',
      'deployment-order' => '100'
    }
  end

  # Resource parameters
  def resource_parameters
    {
      'name' => 'MyApplication',
      'location' => self.location_as_dir,
      'deployment_plan' => self.deployment_plan,
      'context_root' => '/myapp',
      'enabled' => 'true',
      'type' => 'war',
      'generate_rmi_stubs' => 'true',
      'availability_enabled' => 'true',
      'lb_enabled' => 'true',
      'keep_state' => 'true',
      'verify' => 'true',
      'precompile_jsp' => 'true',
      'async_replication' => 'true',
      'properties' => {'java-web-start-enabled' => 'false'},
      'deployment_order' => 100
    }
  end
end