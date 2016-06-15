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

class Redfish::TestInterpolater < Redfish::TestCase
  def test_build_variable_map
    context = create_simple_context(Redfish::Executor.new)

    map = Redfish::Interpreter::Interpolater.send(:build_variable_map, context)

    assert_equal map,
                 {
                   'domain_name' => 'domain1',
                   'glassfish_home' => '/opt/payara-4.1.151',
                   'domain_directory' => "#{test_domains_dir}/domain1",
                   'domains_directory' => test_domains_dir
                 }

    context.file('a', '/tmp/a.txt')
    context.file('b', '/tmp/b.txt')

    map = Redfish::Interpreter::Interpolater.send(:build_variable_map, context)

    assert_equal map,
                 {
                   'domain_name' => 'domain1',
                   'glassfish_home' => '/opt/payara-4.1.151',
                   'domain_directory' => "#{test_domains_dir}/domain1",
                   'domains_directory' => test_domains_dir,
                   'file:a' => '/tmp/a.txt',
                   'file:b' => '/tmp/b.txt'
                 }
  end

  def test_interpolate_data
    data = {
      'a' => 'XXX{{domain_name}}XXX',
      'b' => 1,
      'c' => 1.2,
      'd' => true,
      'e' => false,
      'f' => nil,
      'g' => {
        '1' => '{{domain_name}}',
        '2' => {
          'p' => '{{X}}'
        }
      }
    }
    data2 = Redfish::Interpreter::Interpolater.send(:interpolate_data, data, {'domain_name' => 'domain1', 'X' => 'x'})

    assert_equal data2, {'a' => 'XXXdomain1XXX',
                         'b' => 1,
                         'c' => 1.2,
                         'd' => true,
                         'e' => false,
                         'f' => nil,
                         'g' => {'1' => 'domain1', '2' => {'p' => 'x'}}}

    e = assert_raises(RuntimeError) { Redfish::Interpreter::Interpolater.send(:interpolate_data, {'a' => '{{domain_name}}'}, {}) }
    assert_equal e.message, "Attempting to interpolate value '{{domain_name}}'  resulted in inability to locate context data 'domain_name'"
  end

  def test_interpolate
    data = {
      'a' => 'XXX{{domain_name}}XXX',
      'g' => {
        '1' => '{{domain_name}}',
      }
    }
    context = create_simple_context(Redfish::Executor.new)
    data2 = Redfish::Interpreter::Interpolater.interpolate(context, data)

    assert_equal data2, {'a' => 'XXXdomain1XXX', 'g' => {'1' => 'domain1'}}
  end
end
