# frozen_string_literal: true

module Rottomation
  # Comment
  class Entity
    def to_s
      JSON.pretty_generate(to_hash)
    end

    def to_json(*_args)
      to_hash.compact.to_json
    end

    private

    def to_hash
      instance_variables.each_with_object({}) do |var, hash|
        hash[var.to_s.delete('@')] = instance_variable_get(var)
      end
    end
  end
end
