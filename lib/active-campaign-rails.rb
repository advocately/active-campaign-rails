require "active-campaign-rails/version"
require "active-campaign-rails/utils"
require "active-campaign-rails/errors"
require "active-campaign-rails/client"
require 'rest-client'

class ActiveCampaign

  # Makes the Client's methods available to an instance of the ActiveCampaign class
  include ActiveCampaign::Client

  attr_reader :api_endpoint, :api_key

  def initialize(args)

    # Parse args into instance_variable
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    # Set default api_output to json if not set
    @api_output = 'json' if @api_output == nil

  end


  def method_missing(api_action, *args, &block)

    # Generate api_url
    api_url = generate_api_url(api_action)

    # Check method for api_action given
    case action_calls[api_action][:method]
    when 'get'

      # Generate API parameter from given argument
      api_params = (args.any?) ? args.first.map{|k,v| "#{k}=#{v}"}.join('&') : nil

      # Join API url and API parameters
      api_url = api_params ? "#{api_url}&#{api_params}" : api_url

      # Make a call to API server with GET method
      response = RestClient.get(api_url)

      # Return response from API server
      # Default to JSON
      return handle_json_response(response)

    when 'post'

      # API parameters for POST method
      api_params = args.first

      # For event tracking the visit param must have a json value
      if visit = api_params[:visit]
        api_params[:visit] = visit.to_json if visit.is_a?(Hash)
      end

      # Make a call to API server with POST method
      response = RestClient.post(api_url, api_params)

      # Return response from API server
      # Default to JSON
      return handle_json_response(response)

    when 'delete'

      # API parameters for DELETE method
      api_params = args.first.merge(api_key: @api_key, api_output: @api_output)

      api_url = "#{action_calls[api_action][:endpoint] || @api_endpoint}#{action_calls[api_action][:path] || '/admin/api.php'}"

      # Make a call to API server with DELETE method
      response = RestClient::Request.execute(method: :delete, url: api_url, headers: { params: api_params })

      # Return response from API server
      # Default to JSON
      return handle_json_response(response)

    end

  end

private

  def generate_api_url api_action
    host = action_calls[api_action][:endpoint] || @api_endpoint
    path = action_calls[api_action][:path]     || '/admin/api.php'

    "#{host}#{path}?api_key=#{@api_key}&api_action=#{api_action.to_s}&api_output=#{@api_output}"
  end

  def handle_json_response(response)
    body = ActiveCampaignRails::Utils.symbolize_keys(JSON.load(response.body))
    case response.code
    when 200, 201, 202, 204
      if body[:result_code] == 1
        body
      else
        if body[:result_message] == "You are not authorized to access this file"
          raise ActiveCampaignRails::AuthorizationError, response
        else
          raise ActiveCampaignRails::GeneralAPIError, response
        end
      end
    when 401
      raise ActiveCampaignRails::AuthenticationError, response
    when 406
      raise ActiveCampaignRails::UnsupportedFormatRequestedError, response
    when 422
      raise ActiveCampaignRails::ResourceValidationError, response
    when 503
      raise ActiveCampaignRails::ServiceUnavailableError, response
    else
      raise ActiveCampaignRails::GeneralAPIError, response
    end
  end
end
