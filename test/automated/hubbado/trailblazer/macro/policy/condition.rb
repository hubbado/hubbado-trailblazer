require_relative "../../../../../test_init"

context "Hubbado" do
  context "Trailblazer" do
    context "Macro" do
      context "Policy" do
        context "Condition" do
          Policy = Class.new do
            def self.build(actor, model)
              new(actor, model)
            end

            attr_reader :actor
            attr_reader :model

            def initialize(actor, model)
              @actor = actor
              @model = model
            end

            def show
              Result.new(true)
            end

            class Result
              def initialize(permitted)
                @permitted = permitted
              end

              def permitted?
                !!@permitted
              end
            end
          end

          condition = Hubbado::Trailblazer::Macro::Policy::Condition.new(
            Policy, :show, :model, :current_user
          )
          options = { current_user: "A user", model: "A model" }
          result = condition.([options, nil])

          test "returns policy result in a trailblazer operation result" do
            assert result.success?
          end

          test "returns policy in a trailblazer operation result" do
            policy = result.to_hash[:policy]
            policy_result = result.to_hash[:policy_result]

            assert policy.actor == "A user"
            assert policy.model == "A model"
            assert policy_result.permitted? == true
          end

          context "Another kind of actor" do
            condition = Hubbado::Trailblazer::Macro::Policy::Condition.new(
              Policy, :show, :model, :current_account
            )
            options = { current_account: "An account", model: "A model" }
            result = condition.([options, nil])


            test "returns policy result in a trailblazer operation result" do
              assert result.success?
            end

            test "returns policy in a trailblazer operation result" do
              policy = result.to_hash[:policy]
              policy_result = result.to_hash[:policy_result]

              assert policy.actor == "An account"
              assert policy.model == "A model"
              assert policy_result.permitted? == true
            end
          end
        end
      end
    end
  end
end
