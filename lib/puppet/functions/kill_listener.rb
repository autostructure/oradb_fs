Puppet::Functions.create_function(:kill_listener) do
 dispatch :kill_listener do
   param 'String',   :home_path
   return_type 'Boolean'
 end

 def kill_listener (home_path)
  command1 = '/bin/ps -ef | /bin/grep tns | /bin/grep ' + home_path + ' | /bin/awk \'$1 == "oracle" {print $2}\''
  pid1 = %x[#{command1}].strip
  if !pid1.empty?
   command2 = '/bin/kill -9 ' + pid1
   %x[#{command2}]
   pid2 = %x[#{command1}]
   if pid2.empty?
    return true 
   else
    return false
   end
  else
   return true
  end
 end
end
