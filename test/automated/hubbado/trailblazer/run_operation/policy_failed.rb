require_relative "../../../../test_init"

context "Hubbado" do
  context "Trailblazer" do
    context "RunOperation" do
      context "PolicyFailed" do
        context "without unauthorized message and policy failed block" do
          include Hubbado::Trailblazer::RunOperation

          class PolicyFailedTestOperation < Trailblazer::Operation
            step Policy::Guard(->(_options, params:, **) { !!params[:allowed] })
          end

          test "raises an exception when the policy fails" do
            current_user = Data.define(:id).new(id: 1)
            exception_message = "User 1 not allowed to run PolicyFailedTestOperation"

            assert_raises Hubbado::Trailblazer::Errors::Unauthorized, exception_message do
              run_operation PolicyFailedTestOperation,
                { allowed: false },
                { current_user: current_user }
            end
          end
        end
      end
    end
  end
end
