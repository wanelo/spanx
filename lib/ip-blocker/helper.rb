module IPBlocker
  module Helper
    def error_exit_with_msg(msg)
      $stderr.puts msg
      exit 1
    end

    def period_marker(resolution, timestamp = Time.now)
      timestamp.to_i / resolution * resolution
    end

    def log(msg)
      puts "#{Time.now}: #{msg}"
    end
  end
end
