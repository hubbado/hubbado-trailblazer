module Hubbado
  module Trailblazer
    module Macro
      # This is used to pre-populate a contract before validating it, so that
      # form options can be built based on the contract values
      #
      # For example, a contract, for a not yet saved assignment, might have
      # timesheet approvers that depend on the client company ID in the
      # contract
      def self.PrepopulateContract(key: nil)
        task = ->((ctx, flow_options), _) do
          ctx[:prepopulated_contract] = key ? key : true

          params = key ? ctx[:params][key] : ctx[:params]

          return ::Trailblazer::Activity::Right, [ctx, flow_options] unless params

          ctx['contract.default'].deserialize(params)

          [::Trailblazer::Activity::Right, [ctx, flow_options]]
        end

        { task: task, id: "PrepopulateContract" }
      end
    end
  end
end
