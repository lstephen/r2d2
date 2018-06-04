module R2D2
  class GooglePayToken
    include Util

    attr_reader :protocol_version, :recipient_id, :verification_keys, :signature, :signed_message

    def initialize(token_attrs, opts={})
      @protocol_version = token_attrs['protocolVersion']
      @recipient_id = opts[:recipient_id]
      @verification_keys = opts[:verification_keys]
      @signature = token_attrs['signature']
      @signed_message = token_attrs['signedMessage']
    end

    def decrypt(private_key_pem)
      verified = verify_and_parse_message

      private_key = OpenSSL::PKey::EC.new(private_key_pem)
      shared_secret = generate_shared_secret(private_key, verified['ephemeralPublicKey'])
      hkdf_keys = derive_hkdf_keys(verified['ephemeralPublicKey'], shared_secret, 'Google')

      verify_mac(hkdf_keys[:mac_key], verified['encryptedMessage'], verified['tag'])
      decrypted = JSON.parse(
        decrypt_message(verified['encryptedMessage'], hkdf_keys[:symmetric_encryption_key])
      )

      expired = decrypted['messageExpiration'].to_f / 1000.0 <= Time.now.to_f
      raise MessageExpiredError if expired

      decrypted
    end

    private

    def verify_and_parse_message
      digest = OpenSSL::Digest::SHA256.new
      signed_bytes = to_length_value(
        'Google',
        recipient_id,
        protocol_version,
        signed_message
      )
      verified = verification_keys['keys'].any? do |key|
        next if key['protocolVersion'] != protocol_version

        ec = OpenSSL::PKey::EC.new(strict_decode64(key['keyValue']))

        begin
          ec.verify(digest, strict_decode64(signature), signed_bytes)
        rescue OpenSSL::PKey::PKeyError
          false
        end
      end

      raise SignatureInvalidError unless verified
      JSON.parse(signed_message)
    end

    private

    def strict_decode64(str)
      str.unpack("m0").first
    end
  end
end
