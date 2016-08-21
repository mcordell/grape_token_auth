# frozen_string_literal: true
module GrapeTokenAuth
  class Utility
    def self.find_with_indifference(hash, key)
      if hash.key?(key.to_sym)
        return hash[key.to_sym]
      elsif hash.key?(key.to_s)
        return hash[key.to_s]
      end
      nil
    end

    def self.humanize(snake_cased)
      snake_cased.to_s.split('_').collect(&:capitalize).join
    end
  end
end
