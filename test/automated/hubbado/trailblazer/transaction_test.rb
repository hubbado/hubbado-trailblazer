require_relative "../../../test_init"
require_relative "../../../support/active_record"

context "Hubbado" do
  context "Trailblazer" do
    context "Transaction" do
      operation = Class.new(Trailblazer::Operation) do
        step Wrap(Hubbado::Trailblazer::Transaction) {
          step :create_record
          step :result
        }

        def create_record(ctx, **)
          User.create!(name: "Test User")
        end

        def result(ctx, result:, **)
          result
        end
      end

      context "when the wrapped steps fail" do
        create_operation = operation.(result: false)

        test "it fails" do
          assert create_operation.failure?
        end

        test "rolls back the transaction when the wrapped steps fail" do
          assert User.count == 0
        end
      end

      context "when the wrapped steps pass" do
        create_operation = operation.(result: true)

        test "it passes" do
          assert create_operation.success?
        end

        test "rolls back the transaction when the wrapped steps fail" do
          assert User.count == 1
        end
      end
    end
  end
end
