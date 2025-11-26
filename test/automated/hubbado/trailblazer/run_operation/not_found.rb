require_relative "../../../../test_init"

context "Hubbado" do
  context "Trailblazer" do
    context "RunOperation" do
      context "NotFound" do
        include Hubbado::Trailblazer::RunOperation

        # This test operation takes one param:
        #
        # - found: a boolean to determine if the model should be found or not
        class NotFoundTestOperation < Trailblazer::Operation
          step :find_model,
            Output(:failure) => End(:not_found)

          def find_model(ctx, params:, **)
            !!params[:found]
          end
        end

        context 'when the model is not found' do
          context 'when there is no not_found block' do
            test 'raises an exception when the model is not found' do
              assert_raises ActiveRecord::RecordNotFound do
                run_operation NotFoundTestOperation, found: false
              end
            end
          end

          context 'when there is a not_found block' do
            test 'runs the not_found block' do
              result = run_operation(NotFoundTestOperation, found: false) do |result|
                result.not_found { "block_not_found_result" }
              end

              assert result == "block_not_found_result"
            end
          end

          context 'when the model is found' do
            test 'runs the success block' do
              result = run_operation(NotFoundTestOperation, found: true) do |result|
                result.success { "success_result" }
                result.not_found { "block_not_found_result" }
              end

              assert result == "success_result"
            end
          end
        end
      end
    end
  end
end
