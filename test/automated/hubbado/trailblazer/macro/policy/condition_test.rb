require_relative "../../../../../test_init"

context "Hubbado" do
  context "Trailblazer" do
    context "Macro" do
      context "Policy" do
        context "Condition" do
          Policy = Class.new do
            def self.build(current_user, model)
              new(current_user, model)
            end

            attr_reader :current_user
            attr_reader :model

            def initialize(current_user, model)
              @current_user = current_user
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

          condition = Hubbado::Trailblazer::Macro::Policy::Condition.new(Policy, :show, :model)
          options = { current_user: "A user", model: "A model" }
          result = condition.([options, nil])

          test "returns policy result in a trailblazer operation result" do
            assert result.success?
          end

          test "returns policy in a trailblazer operation result" do
            policy = result.to_hash[:policy]
            policy_result = result.to_hash[:policy_result]

            assert policy.current_user == "A user"
            assert policy.model == "A model"
            assert policy_result.permitted? == true
          end
        end
      end
    end
  end
end
