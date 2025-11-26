module Hubbado
  module Trailblazer
    # This allows you to run an operation and then respond differently based on
    # the result of the operation.
    #
    # run_operation MyOperation do |result|
    #   result.success do |ctx|
    #     ...
    #  end
    #
    #  result.policy_failed do |ctx|
    #    # This is optional if not used the operation will raise an exception
    #    ...
    #    # Also optionally you can raise the default exception, it will not be raised
    #    # if the block is executed otherwise when the block is finished
    #    result.raise_policy_failed
    #  end
    #
    #  result.not_found do |ctx|
    #    ...
    #  end
    #
    #  result.validation_failed do |ctx|
    #    ...
    #  end
    #
    #  result.otherwise do |ctx|
    #   # This is optional if not used the operation will raise an exception
    #    ...
    #   # Also optionally you can raise the default exception, it will not be raised
    #   # if the block is executed otherwise when the block is finished
    #   result.raise_operation_failed
    #  end
    # end
    #
    # ctx is the context built by the operation.
    #
    # If there is a policy failure and you have not implemented
    # `result.policy_failed` then an exception will be raised.
    #
    # If the operation has not_found terminus and you have not
    # implemented `result.not_found` then ActiveRecord::RecordNotFound will be raised.
    #
    # If the operation fails (due to non-policy error) and you have not
    # implemented `result.otherwise` then an exception will be raised.
    #
    # Note, it is on purpose that implementing `result.otherwise` is not enough
    # to stop an exception being raised if the policy fails. This to prevent a
    # `result.otherwise` block rendering a form when the policy failed.
    #
    # We also considered TrailblazerEndpoint in place of this, but it seemed to
    # be complicated for what it quite a simple usecase
    #
    # Tracing operations
    #
    # Setting the ENV variable TRACE_OPERATION to the class name of an
    # operation (or to "_all") will cause the operation to be run with "wtf?"
    # rather than `call`, outputting the trace of the operation, and showing
    # which step failed, to stdout (not logging)
    #
    # This is useful when debugging traces
    module RunOperation
      include TemplateMethod

      # Implement this if params need pre-processing before being passed to the operation
      # For example, a controller needs to turn params into an unsafe hash
      template_method :_run_params do |params|
        params
      end

      # Implement this to inject additional context into the operation
      # For example, a a controller can pass in current_user
      template_method :_run_options do |ctx|
        ctx
      end

      def _run_runtime_options(ctx = {}, *dependencies)
        [_run_options(ctx), *dependencies]
      end

      def run_operation(operation, params = self.params, *options)
        trace_operation = TraceOperation.(operation)
        operation_method = trace_operation ? 'wtf?' : 'call'

        operation_arguments = { params: _run_params(params) }
        operation_arguments[:request] = request if respond_to?(:request)
        operation_arguments.merge!(*_run_runtime_options(*options))

        ctx = operation.send(operation_method, operation_arguments)

        result = Result.new(operation, ctx, trace_operation)

        yield(result) if block_given?

        if ctx['result.policy.default']&.failure?
          result.raise_policy_failed unless result.policy_failed_executed?
        elsif !result.not_found_executed? && ctx.terminus.to_h[:semantic] == :not_found
          result.raise_not_found
        elsif ctx.failure? && !result.validation_failed_executed? && !result.not_found_executed? && !result.otherwise_executed?
          result.raise_operation_failed
        end

        result.returned
      end

      class Result
        include Hubbado::Log::Dependency

        attr_reader :returned
        attr_reader :trace_operation

        def initialize(operation, ctx, trace_operation)
          @operation = operation
          @ctx = ctx
          @trace_operation = trace_operation
        end

        def log_level
          trace_operation ? :debug : :info
        end

        def success
          return unless ctx.success?

          @success_executed = true
          @returned = yield(ctx)

          logger.send(log_level, "Success block executed for operation #{operation}")
          @returned
        end

        def policy_failed
          return unless ctx['result.policy.default']&.failure?

          @policy_failed_executed = true
          @returned = yield(ctx)

          logger.send(log_level, "Policy failed block executed for operation #{operation}")
          @returned
        end

        def validation_failed
          return if success_executed?

          contract = ctx['contract.default']
          # TODO: We cannot call `contract.valid?` here, since the following
          # steps will have converted form errors from strings to symbols:
          #
          # contract = Companies::Controls::Contracts::InviteMember.example
          # contract.validate({name: 'Some name', email: 'email@example.com', role: :staff)
          # contract.errors.add :email, :taken
          # contract.valid?
          #
          # This only happens if errors are added outside of the validation
          return if contract.nil? || contract.errors.full_messages.empty?

          @validation_failed_executed = true
          @returned = yield(ctx)

          if trace_operation
            logger.send(
              log_level,
              "Validation failed: #{ctx['contract.default'].errors.full_messages.join(', ')}"
            )
          else
            logger.send(log_level, "Validation failed")
          end
          @returned
        end

        def not_found
          return unless ctx.terminus.to_h[:semantic] == :not_found

          @not_found_executed = true
          @returned = yield(ctx)

          logger.send(log_level, "Not found block executed for operation #{operation}")
          @returned
        end

        def otherwise
          return if executed?

          @otherwise_executed = true
          @returned = yield(ctx)

          logger.send(log_level, "Otherwise block executed for operation #{operation}")
          @returned
        end

        def raise_not_found
          msg = "Record for operation #{operation.name} not found"

          raise ActiveRecord::RecordNotFound, msg
        end

        def raise_operation_failed
          msg = "Operation #{operation.name} failed"

          error_messages = ctx['contract.default']&.errors&.full_messages

          if error_messages&.any?
            msg += " with errors:\n\n#{error_messages.map { |e| "  - #{e}" }.join("\n")}"
          end

          raise StandardError, msg
        end

        def raise_policy_failed
          current_user = ctx[:current_user]
          true_user = ctx[:true_user]

          msg = "User #{current_user&.id}/#{true_user&.id} (#{current_user&.roles&.join ', '}) " \
                "not allowed to run #{operation.name}"

          raise Hubbado::Trailblazer::Errors::Unauthorized.new(msg, ctx['result.policy.default'][:policy_result])
        end

        def success_executed?
          !!@success_executed
        end

        def policy_failed_executed?
          !!@policy_failed_executed
        end

        def validation_failed_executed?
          !!@validation_failed_executed
        end

        def not_found_executed?
          !!@not_found_executed
        end

        def otherwise_executed?
          !!@otherwise_executed
        end

        def executed?
          success_executed? ||
            policy_failed_executed? ||
            validation_failed_executed? ||
            not_found_executed? ||
            otherwise_executed?
        end

        private

        attr_reader :operation
        attr_reader :ctx
      end
    end
  end
end
