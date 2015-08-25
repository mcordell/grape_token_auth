module GrapeTokenAuth
  # Error when an undefined scope was attempted to be used
  class ScopeUndefinedError < StandardError
    def initialize(msg, scope = nil)
      msg ||= "Trying to use an undefined scope #{scope}. A proper \
               scope to resource class mapping must be set up in the \
               GrapeTokenAuth configuration."
      super(msg)
    end
  end

  # Error when end-user has not configured any mappings
  class MappingsUndefinedError < StandardError
    def message
      'GrapeTokenAuth mapping are undefined. Define your mappings' +
        ' within the GrapeTokenAuth configuration'
    end
  end

  class Unauthorized < StandardError
  end

  class SecretNotSet < StandardError
    def message
      'GrapeTokenAuth secret is not set, define your secret with a' +
        ' safe random key in the GrapeTokenAuth configuration'
    end
  end
end
