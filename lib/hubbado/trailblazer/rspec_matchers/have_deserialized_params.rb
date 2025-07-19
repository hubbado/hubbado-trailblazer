module Hubbado
  module Trailblazer
    module RspecMatchers
      module DeserializeContractParams
        extend RSpec::Matchers::DSL

        matcher :have_deserialized_params do |key: nil|
          match(notify_expectation_failures: true) do |ctx|
            expect(ctx[:deserialized_params]).to eq(key || true)
          end
        end

        RSpec.configure do |rspec|
          rspec.include self, type: :operation
        end
      end
    end
  end
end
