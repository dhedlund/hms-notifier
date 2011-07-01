require 'restclient'

class HubAPI
  attr_accessor :logger, :base_uri

  def initialize(base_uri, options={})
    @base_uri = base_uri.chomp '/'
    @logger = options[:logger] || Logger.new(nil)
  end

  def get(path, options={})
    handle_request :get, "#{@base_uri}#{path}", options
  end


  protected

  def handle_request(method, uri, options={})
    begin
      res = RestClient.send(method, uri, {:accept, :json})
      log_request(Logger::INFO, method, uri, options)
      log_response(Logger::INFO, res)
      data = ActiveSupport::JSON.decode res

    rescue RestClient::Exception => e
      log_request(Logger::ERROR, method, uri, options)
      log_response(Logger::ERROR, e.response)
      raise

    rescue Errno::ETIMEDOUT => e
      log_request(Logger::WARN, method, uri, options)
      @logger.warn e.to_s # known/expected, don't need full backtrace
      raise

    rescue => e
      log_request(Logger::ERROR, method, uri, options)
      @logger.error e
      raise
    end

    data
  end

  def log_request(level, method, uri, options)
    m = method.to_s.upcase
    @logger.add(level, "#{m} #{filter_password(uri)} #{options.inspect}")
  end

  def log_response(level, response)
    return unless response
    @logger.add(level, response.description)
    @logger.debug "HEADERS: #{response.headers.inspect}"
    @logger.debug "BODY: #{response.body}"
  end

  def filter_password(uri)
    uri.sub(/[^:]+@/, '*****@')
  end

end
