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

module Redfish
  module Tasks
    module Glassfish
      class ResourceAdapterCleaner < BaseCleanerTask
        def cascade_clean(element)
          t = run_context.task('connector_connection_pool_cleaner', 'resource_adapter_name' => element, 'expected' => [])
          t.action(:clean)
          t.converge

          t = run_context.task('admin_object_cleaner', 'resource_adapter_name' => element, 'expected' => [])
          t.action(:clean)
          t.converge
          t
        end
      end
    end
  end
end
