require_relative "../../../../test_init"

context "Hubbado" do
  context "Trailblazer" do
    context "Macro" do
      context "Policy" do
        PolicyKlass = Class.new;

        test "returns trailblazer macro policy step" do
          trailblazer_step = Hubbado::Trailblazer::Macro.Policy(PolicyKlass, :show)
          task = trailblazer_step[:task]

          assert task.class == Trailblazer::Macro::Policy::Eval
          assert task.instance_variable_get("@name") == :default
        end

        test "returns trailblazer macro policy step with a custom name" do
          trailblazer_step = Hubbado::Trailblazer::Macro.Policy(
            PolicyKlass, :show, name: :custom_name
          )
          task = trailblazer_step[:task]

          assert task.class == Trailblazer::Macro::Policy::Eval
          assert task.instance_variable_get("@name") == :custom_name
        end

        context "Build" do
          test "returns a Condition instance" do
            condition = Hubbado::Trailblazer::Macro::Policy.build(
              PolicyKlass, :show, :model, :current_user
            )

            assert condition.class == Hubbado::Trailblazer::Macro::Policy::Condition
          end
        end
      end
    end
  end
end
