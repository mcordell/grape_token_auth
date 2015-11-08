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
  end
end
