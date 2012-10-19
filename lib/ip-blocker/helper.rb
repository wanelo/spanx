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
      puts "#{Time.now}: #{sprintf("%-20s", Thread.current[:name])} - #{msg}"
    end

    def logging(message, &block)
      start = Time.now
      returned_from_block = yield
      elapsed_time = Time.now - start
      log "#{message} (elapsed: #{"%.2f" % (1000 * elapsed_time)}ms)"
      returned_from_block
    rescue Exception => e
      elapsed_time = Time.now - start
      log "error: #{e.message} for #{message} (elapsed: #{"%.1f" % (1000 * elapsed_time)}ms)"
    end

  end
end
