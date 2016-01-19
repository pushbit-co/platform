module RouteHelpers
  def last_json
    JSON.parse(last_response.body, object_class: OpenStruct)
  end
  
  def post_with_gh_signature(path, data={})
    sha1 = OpenSSL::Digest.new('sha1')
    
    header "Content-Type", "application/json"
    header "X-Hub-Signature", "sha1=#{OpenSSL::HMAC.hexdigest(sha1, ENV.fetch('GITHUB_WEBHOOK_TOKEN'), data)}"
    post path, data
  end
  
  def post_with_basic_auth(path, data={})
    token = Digest::MD5.hexdigest "#{ENV.fetch('BASIC_AUTH_SECRET')}#{data['task_id']}"
    basic_authorize(token, "x")
    post path, data
  end
end