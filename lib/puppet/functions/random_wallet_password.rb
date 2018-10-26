Puppet::Functions.create_function(:random_wallet_password) do
 dispatch :random_wallet_password do
   return_type 'String'
 end

 def random_wallet_password

  command = "/bin/dd if=/dev/urandom  count=14 bs=1 2>/dev/null | /bin/od -tx | /bin/head -1 | /bin/sed 's|^00* ||;s| ||g'"
  output = %x[#{command}]
  
  return 'a' + output.strip 

 end
end
