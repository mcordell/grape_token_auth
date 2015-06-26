class MappingsUndefinedError < StandardError
  def message
    'GrapeTokenAuth mapping are undefined'
  end
end
