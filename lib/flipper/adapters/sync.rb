require "flipper/instrumenters/noop"
require "flipper/adapters/sync/synchronizer"
require "flipper/adapters/sync/interval_synchronizer"

module Flipper
  module Adapters
    # TODO: Syncing should happen in a background thread on a regular interval
    # rather than in the main thread only when reads happen.
    class Sync
      include ::Flipper::Adapter

      # Public: The name of the adapter.
      attr_reader :name

      # Public: The synchronizer that will keep the local and remote in sync.
      attr_reader :synchronizer

      # Public: Build a new sync instance.
      #
      # local - The local flipper adapter that should serve reads.
      # remote - The remote flipper adpater that should serve writes and update
      #          the local on an interval.
      # interval - The Float or Integer number of seconds between syncs from
      # remote to local. Default value is set in IntervalSynchronizer.
      def initialize(local, remote, options = {})
        @name = :sync
        @local = local
        @remote = remote
        @synchronizer = options.fetch(:synchronizer) do
          sync_options = {
            raise: false,
          }
          instrumenter = options[:instrumenter]
          sync_options[:instrumenter] = instrumenter if instrumenter
          synchronizer = Synchronizer.new(@local, @remote, sync_options)
          IntervalSynchronizer.new(synchronizer, interval: options[:interval])
        end
        sync
      end

      def features
        sync
        @local.features
      end

      def get(feature)
        sync
        @local.get(feature)
      end

      def get_multi(features)
        sync
        @local.get_multi(features)
      end

      def get_all
        sync
        @local.get_all
      end

      def add(feature)
        result = @remote.add(feature)
        @local.add(feature)
        result
      end

      def remove(feature)
        result = @remote.remove(feature)
        @local.remove(feature)
        result
      end

      def clear(feature)
        result = @remote.clear(feature)
        @local.clear(feature)
        result
      end

      def enable(feature, gate, thing)
        result = @remote.enable(feature, gate, thing)
        @local.enable(feature, gate, thing)
        result
      end

      def disable(feature, gate, thing)
        result = @remote.disable(feature, gate, thing)
        @local.disable(feature, gate, thing)
        result
      end

      private

      def sync
        @synchronizer.call
      end
    end
  end
end
