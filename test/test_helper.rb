ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/spec"
require_relative "support/factory_bot"
require_relative "factories"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include FactoryBot::Syntax::Methods

    # Add more helper methods to be used by all tests here...
    def create_user
      @n = (@n || 0) + 1
      User.create!(email: "user#{@n}_#{Time.now.to_i}@example.com", nickname: "user#{@n}_#{Time.now.to_i % 10000}", password: "password123")
    end
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include FactoryBot::Syntax::Methods
  extend Minitest::Spec::DSL

  class << self
    alias_method :context, :describe unless method_defined?(:context)
  end
end

