module IPBlocker
  module Actor


    class Analyzer
      include IPBlocker::Helper
      attr_accessor :config, :adapter, :writer, :periods

      def initialize config
        @config = config
        #@writer = IPBlocker::Writer.new(config)
        @adapter = IPBlocker::Redis::Adapter.new(config)
        @periods = PeriodCheck.from_config(config)
      end

      def run
        Thread.new do
          Thread.current[:name] = "analyzer"
          log "starting analyzer loop..."
          loop do
            blocked_ips = analyze_all_ips()
            # writer.write!
            sleep config[:analyzer][:analyze_interval]
          end
        end
      end

      def analyze_all_ips
        blocked_ips = []
        ips = adapter.ips
        logging "analyzing #{ips.size} IPs" do
          ips.each do |ip|
            ip = analyze_ip(ip)
            blocked_ips << ip if ip
          end
        end
        blocked_ips
      end

      # Analyze individual IP for all defined periods.  As soon as one
      # rule is triggered, exit the method
      def analyze_ip(ip)
        timestamp = period_marker(config[:collector][:resolution], Time.now.to_i)
        set = adapter.ip_history(ip)
        periods.each do |period|
          start_time = timestamp - period.period_seconds
          set.reverse.inject(0) do |sum, element|
            break if element.ts < start_time
            sum += element.count
            if sum >= period.max_allowed
              return IPBlocker::BlockedIp.new(ip, period, sum, Time.now.to_i)
            end
            sum
          end
        end
        nil
      end
    end
  end
end
