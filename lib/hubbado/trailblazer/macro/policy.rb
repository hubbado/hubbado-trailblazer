module Hubbado
  module Trailblazer
    module Macro
      def self.Policy(policy_class, action, name: :default, model: :model)
        ::Trailblazer::Macro::Policy.step(
          Policy.build(policy_class, action, model), name: name
        )
      end

      module Policy
        def self.build(policy_class, action, model)
          Condition.new(policy_class, action, model)
        end

        # Pundit::Condition is invoked at runtime when iterating the pipe.
        class Condition
          def initialize(policy_class, action, model)
            @policy_class = policy_class
            @action = action
            @model = model
          end

          # Instantiate the actual policy object, and call it.
          def call((options), *)
            policy = build_policy(options)
            result!(policy.send(@action), policy)
          end

          private

          def build_policy(options)
            @policy_class.build(options[:current_user], options[@model])
          end

          def result!(policy_result, policy)
            data = { policy: policy, policy_result: policy_result }

            ::Trailblazer::Operation::Result.new(policy_result.permitted?, data)
          end
        end
      end
    end
  end
end
