module IPBlocker
  class Base

    protected

    def error_exit_with_msg(msg)
      $stderr.puts msg
      exit 1
    end
  end
end
