require "net/http"

class HttpGetClient
  def self.call(uri:, user_agent:, open_timeout:, read_timeout:)
    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = user_agent

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = open_timeout.to_i
    http.read_timeout = read_timeout.to_i
    http.request(request)
  end
end
