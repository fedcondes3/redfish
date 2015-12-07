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
    class LogLevels < AsadminTask
      private

      attribute :levels, :kind_of => Hash, :required => true, :custom_validation => true

      def validate_levels(levels)
        levels.each_pair do |key, value|
          unless %w(SEVERE WARNING INFO CONFIG FINE FINER FINSEST ALL).include?(value)
            raise "Log level '#{key}' has an unknown level #{value}"
          end
        end
      end

      action :set do
        existing = current_levels
        levels_to_update = {}

        self.levels.each_pair do |key, level|
          levels_to_update[key] = level unless existing[key] == level
        end

        unless levels_to_update.empty?
          args = []
          args << levels_to_update.collect{|k,v| "#{k}=#{v}"}.join(':')

          context.exec('set-log-levels', args)

          updated_by_last_action
        end
      end

      def instance_key
        self.levels.collect{|k,v| "#{k}=#{v}"}.join(',')
      end

      def current_levels
        output = context.exec('list-log-levels', [], :terse => true, :echo => false).gsub("[\n]+\n", "\n").split("\n").sort

        current_levels = {}
        output.each do |line|
          key, value = line.split
          next unless key
          # Remove <> brackets around level
          current_levels[key] = value[1, value.size - 2]
        end
        current_levels
      end
    end
  end
end
