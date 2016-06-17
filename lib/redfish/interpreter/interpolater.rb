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

module Redfish #nodoc
  module Interpreter #nodoc

    # Class invoked prior to interpolate data structures prior to interpretation
    class Interpolater
      class << self
        def interpolate(task_context, data)
          interpolate_data(data, build_variable_map(task_context))
        end

        private

        def interpolate_data(data, variable_map)
          data.values.each do |value|
            value.gsub!(/\{\{([^\}]+)\}\}/) do
              variable_map[$1] || (raise "Attempting to interpolate value '#{value}'  resulted in inability to locate context data '#{$1}'")
            end if value.respond_to?(:gsub!)
            if value.is_a?(Hash)
              interpolate_data(value, variable_map)
            end
          end
          data
        end

        def build_variable_map(task_context)
          data = {
            'domain_name' => task_context.domain_name,
            'glassfish_home' => task_context.install_dir,
            'domain_directory' => task_context.domain_directory,
            'domains_directory' => task_context.domains_directory,
          }
          task_context.file_map.each_pair do |key, path|
            data["file:#{key}"] = path
          end
          task_context.volume_map.each_pair do |key, path|
            data["volume:#{key}"] = path
          end
          data
        end
      end
    end
  end
end
