module Redfish
  module Tasks
    class ThreadPool < BaseResourceTask

      attribute :name, :kind_of => String, :required => true
      # Specifies the minimum number of threads in the pool. These are created when the thread pool is instantiated.
      attribute :minthreadpoolsize, :kind_of => Integer, :default => 2
      # Specifies the maximum number of threads the pool can contain.
      attribute :maxthreadpoolsize, :kind_of => Integer, :default => 5
      # Specifies the amount of time in seconds after which idle threads are removed from the pool.
      attribute :idletimeout, :kind_of => Integer, :default => 900
      # Specifies the maximum number of messages that can be queued until threads are available to process them for a network listener or IIOP listener. A value of -1 specifies no limit.
      attribute :maxqueuesize, :kind_of => Integer, :default => 4096

      action :create do
        create("configs.config.server-config.thread-pools.thread-pool.#{self.name}.")
      end

      action :destroy do
        destroy("configs.config.server-config.thread-pools.thread-pool.#{self.name}.")
      end

      def properties_to_record_in_create
        {}
      end

      def properties_to_set_in_create
        property_map = {}

        property_map['idle-thread-timeout-seconds'] = self.idletimeout
        property_map['max-thread-pool-size'] = self.maxthreadpoolsize
        property_map['min-thread-pool-size'] = self.minthreadpoolsize
        property_map['max-queue-size'] = self.maxqueuesize

        property_map
      end

      def do_create
        args = []

        args << '--maxthreadpoolsize' << self.maxthreadpoolsize.to_s
        args << '--minthreadpoolsize' << self.minthreadpoolsize.to_s
        args << '--idletimeout' << self.idletimeout.to_s
        args << '--maxqueuesize' << self.maxqueuesize.to_s
        args << self.name.to_s

        context.exec('create-threadpool', args)
      end

      def do_destroy
        context.exec('delete-threadpool', [self.name])
      end

      def present?
        (context.exec('list-threadpools', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
      end
    end
  end
end