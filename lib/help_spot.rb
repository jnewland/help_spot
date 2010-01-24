require 'hashie'
require 'httparty'
require 'help_spot/version'

class HelpSpot
  include HTTParty
  format :xml
  mattr_inheritable :base

  def initialize(base, user, pass)
    self.class.base_uri base
    self.class.basic_auth user, pass
  end

  # Verify authentication credentials
  #
  def authenticated?
    version = api_request(:get, 'private.version')
    return false if version.errors
    return true if version.results.version
    false
  end

  def create_request(options = {})
    raise ArgumentError unless options[:tNote] && options[:xCategory]
    raise ArgumentError unless options[:sFirstName] || options[:sLastName] || options[:sUserId] || options[:sEmail] || options[:sPhone]
    api_request(:post, 'private.request.create', options, :item => 'request').xRequest.to_i
  end

  def update_request(id, options = {})
    api_request(:post, 'private.request.update', options.merge(:xRequest => id), :item => 'request').xRequest.to_i
  end

  def request(id, options = {})
    response = api_request(:get, 'private.request.get', options.merge(:xRequest => id), :item => 'request')
    #munge even further the request history
    response.request_history = response.request_history.map { |item| item[1].first }
    response
  end

  def search_requests(options = {})
    response = api_request(:get, 'private.request.search', options, {:collection => 'requests', :item => 'request'})
    response
  end

private

  def api_request(http_method, method, options = {}, munge_options = {})
    parsed_options = {}
    if http_method == :get
      parsed_options[:query] = options
    else
      parsed_options[:query] = {}
      parsed_options[:body] = options
    end
    parsed_options[:query].merge!(:method => method)
    response = self.class.send(http_method, '/index.php', parsed_options)
    if munge_options[:collection]
      collection = response[munge_options[:collection]][munge_options[:item]].map { |item| Hashie::Mash.new(item) }
      if collection.length == 1
        collection.first
      else
        collection
      end
    elsif munge_options[:item]
      Hashie::Mash.new(response[munge_options[:item]])
    else
      Hashie::Mash.new(response)
    end
  end

end