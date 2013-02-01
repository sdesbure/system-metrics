require 'thread'

module SystemMetrics
  class AsyncStore

    # An instrumenter that does not send notifications. This is used in the
    # AsyncStore so saving events does not send any notifications, not even
    # for logging.
    class VoidInstrumenter < ::ActiveSupport::Notifications::Instrumenter
      def instrument(name, payload={})
        yield(payload) if block_given?
      end
    end

    def initialize
      puts "aaaaaaaaaaaaaaaaaaaaiaiaiaiaiaiaiaiaiaiai"
      @queue = Queue.new
      @thread = Thread.new do
      puts "bbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaiaiaiaiaiaiaiaiaiaiai"
        set_void_instrumenter
      puts "cccccccccccccaaaaaaaaaaaaaaaaaaaaiaiaiaiaiaiaiaiaiaiai"
        consume
      puts "dddddddddddddddddaaaaaaaaaaaaaaaaaaaaiaiaiaiaiaiaiaiaiaiai"
      end
    end

    def save(events)
      puts "------------------------------- SAVE ! -----------------------"
      @queue << events
    end

    protected
      def set_void_instrumenter
        Thread.current[:"instrumentation_#{notifier.object_id}"] = VoidInstrumenter.new(notifier)
      end

      def notifier
        ActiveSupport::Notifications.notifier
      end

      def consume
        while events = @queue.pop
          puts "---------------------------- CONSUMING ! ------------------------------"
          root_event = SystemMetrics::NestedEvent.arrange(events, :presort => false)
          puts "eeeeeeeeeeeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaiaiaiaiaiaiaiaiaiaiai"
          root_model = create_metric(root_event)
          puts "fffffffffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaaiaiaiaiaiaiaiaiaiaiai"
          root_model.update_attributes(:request_id => root_model.id)
          puts "ggggggggggggggggggggggggggaaaaaaaaaaaaaaaaaaaaiaiaiaiaiaiaiaiaiaiai"
          save_tree(root_event.children, root_model.id, root_model.id)
          puts "hhhhhhhhhhhhhhhhhhhhhhhhhhhaaaaaaaaaaaaaaaaaaaaiaiaiaiaiaiaiaiaiaiai"
        end
      end

      def save_tree(events, request_id, parent_id)
        events.each do |event|
          model = create_metric(event, :request_id => request_id, :parent_id => parent_id)
          save_tree(event.children, request_id, model.id)
        end
      end

      def create_metric(event, merge_params={})
      puts "------------------------------- REALLY SAVE ! -----------------------"

      puts event.inspect
      puts merge_params.inspect
      puts SystemMetrics::Metric.new.inspect
        SystemMetrics::Metric.create(event.to_hash.merge(merge_params))
        puts "------------------------------ END SAVE ---------------------------"
      end

  end
end
