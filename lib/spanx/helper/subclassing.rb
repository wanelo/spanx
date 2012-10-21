module Spanx
  module Helper
    module Subclassing

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods

        def subclasses
          @@subclasses ||= {}
        end

        def subclass_name
          name.split("::").last.downcase
        end

        def subclass_class(subclass)
          subclasses[subclass]
        end

        private

        def inherited(subclass)
          subclasses[subclass.subclass_name] = subclass
        end
      end
    end
  end
end
