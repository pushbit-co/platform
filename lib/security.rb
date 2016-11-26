require 'openssl'
require 'base64'

class Security
  def self.encrypt(data)
    cipher = OpenSSL::Cipher::AES.new(128, :CBC)
    cipher.encrypt
    iv = cipher.random_iv
    cipher.key = ENV.fetch('AES_KEY')
    cipher.iv = iv
    result = Base64.encode64(cipher.update(data) + cipher.final).encode('utf-8').strip
    "1/#{Base64.encode64(iv).encode('utf-8').strip}.#{result}"
  end

  def self.decrypt(data)
    data = data[2..-1] #remove version as unused right now
    data = data.split('.')
    iv = Base64.decode64(data[0].encode('ascii-8bit'))
    encrypted_token = Base64.decode64(data[1].encode('ascii-8bit'))
    decipher = OpenSSL::Cipher::AES.new(128, :CBC)
    decipher.key = ENV.fetch('AES_KEY')
    decipher.iv = iv
    decipher.update(encrypted_token) + decipher.final
  end

  def self.hash(data)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), ENV.fetch('HMAC_KEY'), data)
  end

  def self.get_integration_jwt
    # Private key contents
    private_pem = Base64.decode64(ENV.fetch('GITHUB_INTEGRATION_ENCODED_PRIVATE_PEM'))
    private_key = OpenSSL::PKey::RSA.new(private_pem)

    # Generate the JWT
    payload = {
      iat: Time.now.to_i,           # Issued at time
      exp: 1.minute.from_now.to_i,  # JWT expiration time
      iss: ENV.fetch('GITHUB_INTEGRATION_ID')
    }

    JWT.encode(payload, private_key, "RS256")
  end

  def self.generate_ssh_key(passphrase)
    SSHKey.generate(
      type:       'RSA',
      bits:       ENV.fetch('SSH_KEY_BITS', '4096').to_i,
      passphrase: passphrase
    )
  end

  def self.hash_matches?(data, hash)
    self.hash(data) == hash
  end

  def self.verify_github_signature(payload, sig, token)
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), token, payload)
    Rack::Utils.secure_compare(signature, sig)
  end
end
