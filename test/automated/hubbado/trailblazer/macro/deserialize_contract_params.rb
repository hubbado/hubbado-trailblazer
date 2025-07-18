require_relative "../../../../test_init"

context "Hubbado" do
  context "Trailblazer" do
    context "Macro" do
      context "DeserializeContractParams" do
        Contract = Class.new do
          attr_reader :name

          def deserialize(params)
            @name = params[:name]
          end
        end

        params_key = :user
        task_hash = Hubbado::Trailblazer::Macro.DeserializeContractParams(key: params_key)
        flow_options = {}

        context = {
          params: { params_key => { name: "A name" } },
          "contract.default" => Contract.new
        }
        signal, (ctx, fl_options) = task_hash[:task].([context, flow_options], nil)

        test "returns the macro format" do
          assert task_hash == { task: task_hash[:task], id: "DeserializeContractParams" }
        end

        test "returns right trailblazer activity" do
          assert signal == Trailblazer::Activity::Right
          assert ctx == context
          assert fl_options == flow_options
        end

        test "contract deserializes params" do
          contract = ctx['contract.default']

          assert contract.name == "A name"
        end

        test 'Sets deserialized_params to key in context' do
          assert context[:deserialized_params] == params_key
        end

        context "when params are empty" do
          context = { params: {} }
          signal, (ctx, fl_options) = task_hash[:task].([context, flow_options], nil)

          test "returns right trailblazer activity" do
            assert signal == Trailblazer::Activity::Right
            assert ctx == context
            assert fl_options == flow_options
          end
        end
      end
    end
  end
end
