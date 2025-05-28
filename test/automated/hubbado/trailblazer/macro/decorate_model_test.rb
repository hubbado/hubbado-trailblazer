require_relative "../../../../test_init"

context "Hubbado" do
  context "Trailblazer" do
    context "Macro" do
      context "DecorateModel" do
        Decorator = Class.new do
          def self.build(model, current_user)
            new(model, current_user)
          end

          attr_reader :model
          attr_reader :current_user

          def initialize(model, current_user)
            @model = model
            @current_user = current_user
          end
        end

        task_hash = Hubbado::Trailblazer::Macro.DecorateModel(Decorator)
        flow_options = {}

        context = {
          model: "A model", current_user: "A user"
        }
        signal, (ctx, fl_options) = task_hash[:task].([context, flow_options], nil)

        test "returns the macro format" do
          assert task_hash == { task: task_hash[:task], id: "Decorate" }
        end

        test "returns right trailblazer activity" do
          assert signal == Trailblazer::Activity::Right
          assert ctx == context
          assert fl_options == flow_options
        end

        test "returns decorated object" do
          model = ctx[:model]

          assert model.class == Decorator
          assert model.model == "A model"
          assert model.current_user == "A user"
        end

        context "when model don't exist" do
          test "returns left trailblazer activity" do
            context = { model: nil }
            signal, (ctx, fl_options) = task_hash[:task].([context, flow_options], nil)

            assert signal == Trailblazer::Activity::Left
            assert ctx == context
            assert fl_options == flow_options
          end
        end

        context "when current_user don't exist" do
          test "returns left trailblazer activity" do
            context = { model: "A model", current_user: nil }
            signal, (ctx, fl_options) = task_hash[:task].([context, flow_options], nil)

            assert signal == Trailblazer::Activity::Left
            assert ctx == context
            assert fl_options == flow_options
          end
        end
      end
    end
  end
end
