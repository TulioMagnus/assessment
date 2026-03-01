class BaseService
  def self.call(*args, **kwargs, &block)
    new(*args, **kwargs, &block).call
  end

  Result = Struct.new(:data, :error, keyword_init: true) do
    def success?
      error.blank? && data.present?
    end
  end

  def self.success(data:)
    Result.new(data: data)
  end

  def self.failure(error:)
    Result.new(error: error)
  end

  private

  def success(data:)
    self.class.success(data: data)
  end

  def failure(error:)
    self.class.failure(error: error)
  end
end
