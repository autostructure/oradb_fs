Puppet::Functions.create_function(:os_ls) do
 dispatch :os_ls do
   param 'String',   :path_choice
   return_type 'Array'
 end

 def os_ls (path_choice)

  array_f = ['']

  if path_choice == 'sysinfra_sig'
   command = 'hostname'
   host_name = %x[#{command}].strip
   command = 'ls -lQ /fslink/sysinfra/signatures/oracle/' + host_name + ' | grep -E "[[:graph:]]*\.xml\"" | awk \'$3 == "oracle" {print $9}\' | sed \'s/"//g\' | sort '
  elsif path_choice == 'local_sig'
   command = 'ls -lQ /opt/oracle/signatures | grep -E "[[:graph:]]*\.xml\"" | awk \'$3 == "oracle" {print $9}\' | sed \'s/"//g\' | sort '
  else
   fail
  end

  output = %x[#{command}]
  if !output.empty?
   output.each_line.with_index do | li, index |
    array_f[index] = li.strip
   end
  end
  
  return array_f 

 end
end
