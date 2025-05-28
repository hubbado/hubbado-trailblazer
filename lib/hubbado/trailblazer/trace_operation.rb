module Hubbado
  module Trailblazer
    module TraceOperation
      def self.call(operation)
        [operation.name, '_all'].include?(ENV.fetch('TRACE_OPERATION', nil))
      end
    end
  end
end
