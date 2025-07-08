require_relative "../../../test_init"

context "Hubbado" do
  context "Trailblazer" do
    context "TraceOperation" do
      operation_name = "operation_name"
      AnotherTestOperation = Data.define(:name)
      test_operation = AnotherTestOperation.new(operation_name)

      test "does not trace by default" do
        refute Hubbado::Trailblazer::TraceOperation.(test_operation)
      end

      def trace_operation_env_stub(value)
        original_trace_operation = ENV["TRACE_OPERATION"]
        ENV["TRACE_OPERATION"] = value

        yield

        ENV["TRACE_OPERATION"] = original_trace_operation
      end

      context "when TRACE_OPERATION env var contains _all" do
        test "trace the operation" do
          trace_operation_env_stub "_all" do
            assert Hubbado::Trailblazer::TraceOperation.(test_operation)
          end
        end
      end

      context "when TRACE_OPERATION env var contains operation's name" do
        test "trace the operation" do
          trace_operation_env_stub operation_name do
            assert Hubbado::Trailblazer::TraceOperation.(test_operation)
          end
        end
      end

      context "when TRACE_OPERATION env var does not contains operation's name" do
        test "does not trace the operation" do
          trace_operation_env_stub "another_name" do
            refute Hubbado::Trailblazer::TraceOperation.(test_operation)
          end
        end
      end
    end
  end
end
