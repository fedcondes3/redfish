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

class Redfish::Tasks::TestLibrary < Redfish::Tasks::BaseTaskTest
  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.file = '/opt/jtds/jtds-1.3.1.jar'
    t.library_type = 'ext'

    assert_equal t.to_s, 'library[/opt/jtds/jtds-1.3.1.jar]'
  end

  def test_create_when_no_such_library
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('add-library'),
                                 equals(%w(--type ext --upload false /opt/jtds/jtds-1.3.1.jar)),
                                 equals({})).
      returns('')

    t.file = '/opt/jtds/jtds-1.3.1.jar'
    t.library_type = 'ext'
    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_when_library_exists
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns("jtds-1.3.1.jar\n")

    t.file = '/opt/jtds/jtds-1.3.1.jar'
    t.library_type = 'ext'
    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_destroy_when_library_exists
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns("jtds-1.3.1.jar\n")
    executor.expects(:exec).with(equals(t.context),
                                 equals('remove-library'),
                                 equals(%w(--type ext jtds-1.3.1.jar)),
                                 equals({})).
      returns('')

    t.file = '/opt/jtds/jtds-1.3.1.jar'
    t.library_type = 'ext'
    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end


  def test_destroy_when_library_no_exist
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns('')

    t.file = '/opt/jtds/jtds-1.3.1.jar'
    t.library_type = 'ext'
    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end
end