module Hubbado
  module Trailblazer
    module Macro
      def self.DecorateModel(decorator, model: :model)
        task = ->((ctx, flow_options), _) do
          unless ctx[model] && ctx[:current_user]
            return ::Trailblazer::Activity::Left, [ctx, flow_options]
          end

          ctx[model] = decorator.build(ctx[model], ctx[:current_user])

          [::Trailblazer::Activity::Right, [ctx, flow_options]]
        end

        { task: task, id: "Decorate" }
      end
    end
  end
end
