# frozen_string_literal: true

module Rottomation
  # Top Level Comment
  class HttpRequestBodyBuilder
    def self.inherited(subclass)
      subclass.instance_variable_set(:@have_methods_been_constructed, false)

      subclass.define_singleton_method(:ensure_methods_have_been_constructed) do
        return if @have_methods_been_constructed

        raise NotImplementedError,
              'Rottomation::HttpRequestBodyBuilder inheritors must call construct_methods_and_readers'
      end

      subclass_new_method = subclass.method(:new)
      subclass.define_singleton_method(:new) do |*args, **kwargs, &block|
        ensure_methods_have_been_constructed
        subclass_new_method.call(*args, **kwargs, &block)
      end
    end

    def self.construct_methods_and_readers(bool_params: [], non_bool_params: [], required_params: []) # TODO
      @have_methods_been_constructed = true

      (bool_params + non_bool_params).each do |param|
        attr_reader param

        method_name = bool_params.include?(param) ? "set_#{param}" : "with_#{param}"
        define_method(method_name) do |val|
          instance_variable_set("@#{param}", val)
          self
        end
      end

      define_method(:build) do
        body = {}
        ((bool_params + non_bool_params)).each do |param|
          val = instance_variable_get("@#{param}")
          raise ArgumentError, "Missing required parameter: #{param}" if param.nil? && required_params.include?(param)

          body[param.to_sym] = val unless val.nil?
        end
        body
      end
    end
  end
end
