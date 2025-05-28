module Hubbado
  module Trailblazer
    module Errors
      class Unauthorized < StandardError
        attr_reader :result

        def initialize(message = nil, result = nil)
          @result = result

          super(message)
        end
      end
    end
  end
end
