module IPBlocker
  module Helper
    module Exit
      def error_exit_with_msg(msg)
        $stderr.puts msg
        exit 1
      end
    end
  end
end
