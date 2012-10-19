module IPBlocker
  module Helper
    def period_marker(resolution, timestamp = Time.now)
      timestamp.to_i / resolution * resolution
    end

    def log(msg)
      puts "#{Time.now}: #{msg}"
    end
  end
end
