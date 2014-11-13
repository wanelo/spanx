module Spanx
  module Helper
    module Exit
      def error_exit_with_msg(msg)
        $stderr.puts "Error: #{msg}\n"
        $stderr.puts Spanx::Usage.usage
        exit 1
      end
      def help_exit
        $stdout.puts Spanx::Usage.usage
        exit 0
      end
    end
  end
end
