module ActiveCampaignRails
  class Error < StandardError
    def initialize(response)
      @response = response
    end

    def to_s
      "#{@response.code}: #{@response.body}"
    end
  end

  class TokenError < Error
    def to_s
      "#{@response['error']}: #{@response['error_description']}"
    end
  end

  class AuthenticationError < Error
    # 401, api auth missing or incorrect
  end

  class AuthorizationError < Error
    # 403, lack of permissions

    def to_s
      "403: #{@response.body}"
    end
  end

  class UnsupportedFormatRequestedError < Error
    # 406, invalid format in Accept header
  end

  class ResourceValidationError < Error
    # 422, validation errors
  end

  class GeneralAPIError < Error
    # 500, general/unknown error
  end

  class ServiceUnavailableError < Error
    # 503, maintenance or overloaded
  end
end
