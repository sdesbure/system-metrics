module SystemMetrics
  class Engine < ::Rails::Engine

    attr_accessor :collector, :smc

    config.system_metrics = SystemMetrics::Config.new

    initializer "system_metrics.initialize", :before => "system_metrics.start_subscriber" do |app|
      self.smc = app.config.system_metrics
      raise ArgumentError.new(smc.errors) if smc.invalid?
      self.collector = SystemMetrics::Collector.new(smc.store)
    end

    initializer "system_metrics.start_subscriber", :before => "system_metrics.add_middleware" do |app|
      ActiveSupport::Notifications.subscribe /^[^!]/ do |*args|
        unless smc.notification_exclude_patterns.any? { |pattern| pattern =~ name }
          process_event SystemMetrics::NestedEvent.new(*args)
        end
      end
    end

    initializer "system_metrics.add_middleware", :before => :load_environment_config do |app|
      app.config.middleware.use SystemMetrics::Middleware, collector, smc.path_exclude_patterns
    end

    private

      def process_event(event)
        puts "******************************"
        puts event.inspect
        puts "******************************"
        instrument = smc.instruments.find { |instrument| instrument.handles?(event) }

        if instrument.present?
          unless instrument.ignore?(event)
            instrument.prepare(event)
        puts "------------------------------"
        puts event.inspect
        puts "------------------------------"
            collector.collect_event(event)
          end
        else
          collector.collect_event(event)
        end
      end

  end
end

