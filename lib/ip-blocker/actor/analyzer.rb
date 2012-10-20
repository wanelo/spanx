module IPBlocker
  module Actor
    class Analyzer
      include IPBlocker::Helper
      attr_accessor :config, :adapter, :periods

      def initialize config
        @config = config
        @adapter = IPBlocker::Redis::Adapter.new(config)
        @periods = IPBlocker::PeriodCheck.from_config(config)
      end

      def run
        Thread.new do
          Thread.current[:name] = "analyzer"
          log "starting analyzer loop..."
          loop do
            analyze_all_ips()
            sleep config[:analyzer][:analyze_interval]
          end
        end
      end

      # Look through every IP on the stack. IPs that fulfill a PeriodCheck
      # are pushed onto a redis block list.
      def analyze_all_ips
        blocked_ips = []
        ips = adapter.ips
        logging "analyzing #{ips.size} IPs" do
          ips.each do |ip|
            ip_block = analyze_ip(ip)
            blocked_ips << ip_block if ip_block
          end
        end
        adapter.block_ips(blocked_ips)
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
