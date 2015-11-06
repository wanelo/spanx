module Spanx
  class Usage
    HEADER = %q{Usage: spanx [ --help | <command> ]  [options]}

    def self.usage
      out = ''
      out << HEADER + "\n\n"
      Spanx::CLI.subclasses.each_pair{|command, clazz| out << "#{sprintf '%10s', command}\t#{clazz.description}\n"}
      out << "\nRun 'spanx <command> --help' to see command-specific options.\n"
      out
    end
  end
end
