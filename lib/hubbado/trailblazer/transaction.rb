module Hubbado
  module Trailblazer
    class Transaction
      def self.call((_ctx, _flow_options), *)
        res = nil

        if defined?(ActiveRecord)
          ActiveRecord::Base.transaction do
            res = yield
            raise ActiveRecord::Rollback if res.first.to_h[:semantic] == :failure
          end
        else
          # No transaction support available
          res = yield
        end

        res
      end
    end
  end
end
