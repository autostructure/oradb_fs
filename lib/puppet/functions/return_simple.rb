require 'openssl'
require 'base64'

Puppet::Functions.create_function(:return_simple) do
 dispatch :return_simple do
   param 'String',   :in_var
   # return_type 'String'
 end

 def return_simple (in_var)

  l_1 = 'ke4u0u8BWAJ8V8TjXAMVKglQWA+v2BS8igfynM5SBro='
  l_2 = 'M1Pv4m4s8v5pjFwVpkDidQ=='

  cipher = OpenSSL::Cipher.new("aes-256-cbc")
  cipher.decrypt
  cipher.key = Base64.decode64(l_1)
  cipher.iv = Base64.decode64(l_2)
  
  out_var = cipher.update(Base64.decode64(in_var))
  out_var << cipher.final

  return out_var 

 end
end
