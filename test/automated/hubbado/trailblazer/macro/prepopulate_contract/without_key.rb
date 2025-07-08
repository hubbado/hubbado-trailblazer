require_relative "../../../../../test_init"

context "Hubbado" do
  context "Trailblazer" do
    context "Macro" do
      context "PrepopulateContract" do
        context "Without key" do
          Contract = Class.new do
            attr_reader :name

            def deserialize(params)
              @name = params[:name]
            end
          end

          task_hash = Hubbado::Trailblazer::Macro.PrepopulateContract()
          flow_options = {}

          context = {
            params: { name: "A name" },
            "contract.default" => Contract.new
          }
          signal, (ctx, fl_options) = task_hash[:task].([context, flow_options], nil)

          test "returns the macro format" do
            assert task_hash == { task: task_hash[:task], id: "PrepopulateContract" }
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

          test 'Sets prepopulated contract in context' do
            assert context[:prepopulated_contract]
          end
        end
      end
    end
  end
end
