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
    class Property < AsadminTask
      private

      attribute :key, :kind_of => String, :required => true
      attribute :value, :kind_of => String, :required => true

      private

      action :set do
        when_value_not_set do
          context.exec('set', ["#{self.key}=#{self.value}"], :terse => true, :echo => false)
          updated_by_last_action
          if context.property_cache?
            context.property_cache[self.key] = self.value
          end
        end
      end

      action :ensure do
        when_value_not_set do
          raise "Property '#{self.key}' expected to be '#{self.value}'"
        end
      end

      def when_value_not_set
        cache_present = context.property_cache?
        may_need_update = cache_present ? self.value != context.property_cache[self.key] : true
        if may_need_update
          if cache_present || !(/^#{Regexp.escape("#{self.key}=#{self.value}")}$/ =~ context.exec('get', ["#{self.key}"], :terse => true, :echo => false))
            yield if block_given?
          end
        end
      end
    end
  end
end
