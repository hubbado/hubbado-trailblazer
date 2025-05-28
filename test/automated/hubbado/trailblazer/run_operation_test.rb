require_relative "../../../test_init"

context "Hubbado" do
  context "Trailblazer" do
    context "RunOperation" do
      include Hubbado::Trailblazer::RunOperation

      class TestContract < Reform::Form
        property :valid, virtual: true

        validation valid: :default do
          schema do
            required(:valid).filled
          end
        end
      end

      # This test operation takes four params:
      #
      # - allowed: a boolean to determine if the policy should pass or fail
      # - valid: a boolean to determine if the validation should pass or fail
      # - success: a boolean to determine if the operation should pass or fail
      # - allowed_invalid_contract: an optional boolean to determine if an
      #     invalid contract causes the operation to fail (default false)
      class RunOperationTestOperation < Trailblazer::Operation
        step Contract::Build(constant: TestContract)
        step :add_data
        step Policy::Guard(->(_options, params:, **) { !!params[:allowed] })
        step :validate
        step :run

        def add_data(ctx, **)
          ctx[:data] = 'data'
        end

        def run(_ctx, params:, **)
          !!params[:success]
        end

        # In an actual operation this is normally just:
        #
        #   step Contract::Validate()
        #
        # We have a manually defined step here to allow to control whether failed
        # validatio causes the operation to fail or not
        def validate(ctx, params:, **)
          contract = ctx['contract.default']

          contract.validate(params)
          if contract.valid?
            true
          else
            !!params[:allowed_invalid_contract]
          end
        end
      end

      context 'when there is a failed_policy block' do
        def test_operation(allowed:, success:, return_from_block: nil)
          returned_result = nil
          returned_ctx = nil

          returned_from_block = run_operation(
            RunOperationTestOperation, allowed: allowed, success: success, valid: true
          ) do |result|
            returned_result = result

            result.success do |ctx|
              returned_ctx = ctx
              return_from_block
            end

            result.policy_failed do |ctx|
              returned_ctx = ctx
              return_from_block
            end

            result.otherwise do |ctx|
              returned_ctx = ctx
              return_from_block
            end
          end

          [returned_result, returned_ctx, returned_from_block]
        end

        test 'runs the success block only when the operation is successful' do
          result, _ctx = test_operation(allowed: true, success: true)

          assert result.success_executed?
          refute result.policy_failed_executed?
          refute result.validation_failed_executed?
          refute result.otherwise_executed?
        end

        test 'yields the ctx to the successful block' do
          _result, ctx = test_operation(allowed: true, success: true)

          assert ctx[:data] == 'data'
        end

        test "returns the successful block's result" do
          _result, _ctx, returned_from_block = test_operation(
            allowed: true, success: true, return_from_block: :returned
          )

          assert returned_from_block == :returned
        end

        test 'runs the policy failed block only when the policy is unsuccessful' do
          result, _ctx = test_operation(allowed: false, success: true)

          refute result.success_executed?
          assert result.policy_failed_executed?
          refute result.validation_failed_executed?
          refute result.otherwise_executed?
        end

        test 'yields the ctx to the policy failed block' do
          _result, ctx = test_operation(allowed: false, success: true)

          assert ctx[:data] == 'data'
        end

        test "returns the policy failed block's result" do
          _result, _ctx, returned_from_block = test_operation(
            allowed: false, success: true, return_from_block: :returned
          )

          assert returned_from_block == :returned
        end

        test 'runs the otherwise block only when the operation is unsuccessful' do
          result, _ctx = test_operation(allowed: true, success: false)

          refute result.success_executed?
          refute result.policy_failed_executed?
          refute result.validation_failed_executed?
          assert result.otherwise_executed?
        end

        test 'yields the ctx to the otherwise block' do
          _result, ctx = test_operation(allowed: true, success: false)

          assert ctx[:data] == 'data'
        end

        test "returns the otherwise block's result" do
          _result, _ctx, returned_from_block = test_operation(
            allowed: true, success: false, return_from_block: :returned
          )

          assert returned_from_block == :returned
        end
      end

      context 'when there is a failed validation block' do
        def test_operation(valid:, success:, allowed_invalid_contract: nil, return_from_block: nil)
          allowed_invalid_contract = false if allowed_invalid_contract.nil?

          returned_result = nil
          returned_ctx = nil

          returned_from_block = run_operation(
            RunOperationTestOperation,
            allowed: true,
            success: success,
            valid: valid,
            allowed_invalid_contract: allowed_invalid_contract
          ) do |result|
            returned_result = result

            result.success do |ctx|
              returned_ctx = ctx
              return_from_block
            end

            result.validation_failed do |ctx|
              returned_ctx = ctx
              return_from_block
            end

            result.otherwise do |ctx|
              returned_ctx = ctx
              return_from_block
            end
          end

          [returned_result, returned_ctx, returned_from_block]
        end

        test 'runs the success block only when the operation is successful' do
          result, _ctx = test_operation(valid: true, success: true)

          assert result.success_executed?
          refute result.validation_failed_executed?
          refute result.otherwise_executed?
        end

        test 'runs the validation failed block only when the validation is unsuccessful' do
          result, _ctx = test_operation(valid: nil, success: false)

          refute result.success_executed?
          assert result.validation_failed_executed?
          refute result.otherwise_executed?
        end

        # This is a an edge case I found whilst implementing this, but we do have situations
        # where the operation is marked as successful but the contract has errors
        test 'does not run validation failed if the operation was successful' do
          result, _ctx = test_operation(valid: false, success: true, allowed_invalid_contract: true)

          assert result.success_executed?
          refute result.validation_failed_executed?
          refute result.otherwise_executed?
        end

        test 'yields the ctx to the validation failed block' do
          _result, ctx = test_operation(valid: false, success: false)

          assert ctx[:data] == 'data'
        end

        test "returns the otherwise block's result" do
          _result, _ctx, returned_from_block = test_operation(
            valid: false, success: false, return_from_block: :returned
          )

          assert returned_from_block == :returned
        end
      end

      context 'when there is no failed_policy block' do
        test 'raises an exception when the policy fails' do
          assert_raises Hubbado::Trailblazer::Errors::Unauthorized do
            run_operation RunOperationTestOperation, allowed: false, valid: true, success: true
          end
        end
      end

      context 'when there is no failed_validation block but otherwise is given' do
        test 'ran the otherwise block' do
          returned_result = nil

          run_operation(RunOperationTestOperation, allowed: true, valid: false, success: false) do |result|
            result.otherwise { true }
            returned_result = result
          end

          assert returned_result.otherwise_executed?
        end
      end

      context 'when there is no otherwise block ' do
        test 'raises an exception when the operation fails' do
          assert_raises StandardError, "Operation RunOperationTestOperation failed" do
            run_operation RunOperationTestOperation, allowed: true, valid: true, success: false
          end
        end
      end
    end
  end
end
