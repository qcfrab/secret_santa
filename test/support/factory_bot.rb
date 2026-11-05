# test/support/factory_bot.rb
# Provides a lightweight FactoryBot mock/adapter if factory_bot gem is not loaded,
# or integrates cleanly with real FactoryBot if present.

module FactoryBot
  @factories = {}
  @sequences = Hash.new(0)

  class DefinitionProxy < BasicObject
    def initialize(name, &block)
      @name = name
      @attributes = {}
      instance_eval(&block) if block
    end

    def method_missing(attr_name, *args, &block)
      if block
        @attributes[attr_name] = block
      elsif args.any?
        @attributes[attr_name] = args.first
      else
        super
      end
    end

    def respond_to_missing?(_attr_name, _include_private = false)
      true
    end

    def evaluate(overrides = {})
      resolved = {}
      @attributes.each do |k, v|
        resolved[k] = v.respond_to?(:call) ? v.call : v
      end
      resolved.merge(overrides)
    end
  end

  class << self
    def define(&block)
      instance_eval(&block)
    end

    def factory(name, &block)
      @factories[name.to_sym] = DefinitionProxy.new(name, &block)
    end

    def sequence(name, &block)
      @sequences[name.to_sym] = block || ->(n) { n }
    end

    def generate(name)
      sym = name.to_sym
      seq = @sequences[sym] || ->(n) { "#{sym}_#{n}" }
      @sequences["_c_#{sym}".to_sym] ||= 0
      n = (@sequences["_c_#{sym}".to_sym] += 1)
      seq.call(n)
    end

    def attributes_for(name, overrides = {})
      factory = @factories[name.to_sym] || raise("Factory :#{name} not defined")
      factory.evaluate(overrides)
    end

    def build(name, overrides = {})
      klass = name.to_s.camelize.constantize
      klass.new(attributes_for(name, overrides))
    end

    def create(name, overrides = {})
      klass = name.to_s.camelize.constantize
      klass.create!(attributes_for(name, overrides))
    end

    def create_list(name, amount, overrides = {})
      Array.new(amount) { create(name, overrides) }
    end
  end

  module Syntax
    module Methods
      def create(name, overrides = {})
        FactoryBot.create(name, overrides)
      end

      def build(name, overrides = {})
        FactoryBot.build(name, overrides)
      end

      def attributes_for(name, overrides = {})
        FactoryBot.attributes_for(name, overrides)
      end

      def create_list(name, amount, overrides = {})
        FactoryBot.create_list(name, amount, overrides)
      end

      def generate(name)
        FactoryBot.generate(name)
      end
    end
  end
end unless defined?(FactoryBot)
