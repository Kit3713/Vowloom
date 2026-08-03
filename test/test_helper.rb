ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Parallel schema setup can overwhelm small local PostgreSQL instances and
    # has exposed native pg crashes on macOS. Keep the default deterministic;
    # CI or a larger host may opt in with RAILS_TEST_WORKERS=2 (or more).
    parallelize(workers: ENV.fetch("RAILS_TEST_WORKERS", 1).to_i)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
