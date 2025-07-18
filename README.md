# Hubbado Trailblazer

Enhanced Trailblazer operation utilities for Ruby applications with improved error handling, operation execution patterns, and ActiveRecord integration.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hubbado-trailblazer'
```

And then execute:

```bash
$ POSTURE=dev ./install-gems.sh
```

Or install it yourself as:

```bash
$ gem install hubbado-trailblazer
```

## Overview

This gem extends Trailblazer operations with enhanced execution patterns, automatic transaction handling, and structured error handling. It provides:

- **RunOperation**: A mixin for executing operations with structured result handling
- **Transaction**: Automatic ActiveRecord transaction wrapping for operations
- **Macros**: Custom operation macros for common patterns (policies, decorators, contract prepopulation)
- **Enhanced Error Handling**: Structured error responses with proper exception types
- **Operation Tracing**: Debug capabilities for operation execution flow

## Usage

### Basic Operation Execution

Create a concern to include the RunOperation functionality in your controllers:

```ruby
module Concern
  module Trailblazer
    extend ActiveSupport::Concern

    included do
      include Hubbado::Trailblazer::RunOperation

      def _run_options(options)
        options.merge(
          current_user: current_user || Users::Models::User.guest,
        )
      end

      # Trailblazer takes all the parameters, no permit for us!
      def _run_params(params)
        params = params.to_unsafe_hash if params.respond_to?(:to_unsafe_hash)
        params
      end
    end
  end
end
```

Then include it in your controllers:

```ruby
class UsersController < ApplicationController
  include Concern::Trailblazer

  def create
    run_operation Users::Create do |result|
      result.success do |ctx|
        redirect_to user_path(ctx[:user])
      end

      result.validation_failed do |ctx|
        render :new, locals: { contract: ctx['contract.default'] }
      end

      result.policy_failed do |ctx|
        redirect_to root_path, alert: 'Not authorized'
      end

      result.otherwise do |ctx|
        redirect_to users_path, alert: 'Something went wrong'
      end
    end
  end
end
```

### Transaction Handling

Wrap operations in ActiveRecord transactions that automatically rollback on failure:

```ruby
class Users::Create < Trailblazer::Operation
  step Wrap(Hubbado::Trailblazer::Transaction) {
    step Model(User, :new)
    step Contract::Build(constant: Users::CreateContract)
    step Contract::Validate()
    step Contract::Persist()
  }
end
```

### Custom Macros

#### Policy Macro

Enhanced policy handling for use with Hubbado::Policy:

```ruby
class Users::Update < Trailblazer::Operation
  step Hubbado::Trailblazer::Macro::Policy(Users::UpdatePolicy)
  # ... other steps
end
```

#### Decorate Model Macro

Automatically decorate models using `SomeDecorator.build(model, current_user)`:

```ruby
class Users::Show < Trailblazer::Operation
  step Model(User, :find)
  step Hubbado::Trailblazer::Macro::DecorateModel(UserDecorator)
end
```

#### Prepopulate Contract Macro

Prepopulate Reform contracts with values from params without validation:

```ruby
class Users::Edit < Trailblazer::Operation
  step Model(User, :find)
  step Contract::Build(constant: Users::UpdateContract)
  step Hubbado::Trailblazer::Macro::DeserializeContractParams()
end
```

In addition, there is a RSpec matcher `have_deserialized_params` for this macro and
has to be required manually:
```ruby
require 'hubbado/trailblazer/rspec_matchers/have_deserialized_params'
```

## Operation Tracing

Debug operation execution by setting the `TRACE_OPERATION` environment variable:

```bash
# Trace a specific operation
TRACE_OPERATION=Users::Create rails console

# Trace all operations
TRACE_OPERATION=_all rails console
```

This will output detailed execution traces showing which steps pass or fail.

## Advanced Features

### Custom Runtime Options

The concern template methods can be customized for your application's needs:

```ruby
def _run_options(options)
  options.merge(
    current_user: current_user || Users::Models::User.guest,
    request: request,
    session: session
  )
end

def _run_params(params)
  params = params.to_unsafe_hash if params.respond_to?(:to_unsafe_hash)
  params
end
```

### Error Handling

The gem provides structured error handling with specific exception types:

- `Hubbado::Trailblazer::Errors::Unauthorized` - Raised when policies fail
- `Hubbado::Trailblazer::OperationFailed` - Raised when operations fail unexpectedly

## Testing

Run the test suite:

```bash
$ ./test.sh
```

The gem uses TestBench for testing and includes comprehensive test coverage for all operation patterns and macros.

## Requirements

- Ruby >= 3.2
- ActiveRecord
- Trailblazer Operation
- Reform (for contract testing)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Make your changes and add tests
4. Ensure all tests pass (`./test.sh`)
5. Commit your changes (`git commit -am 'Add some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create a new Pull Request

## License

This gem is available under the MIT License. See the LICENSE file for more details.
