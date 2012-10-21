module Spanx
  module Helper
    module Exit
      def error_exit_with_msg(msg)
        $stderr.puts "Error: #{msg}"
        Spanx::Usage.print
        exit 1
      end
    end
  end
end
