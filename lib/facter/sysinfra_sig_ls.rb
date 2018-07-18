Facter.add(:sysinfra_sig_ls) do
 confine :kernel => 'Linux'
 setcode do

  ls_array = ['']
  host_name = Facter.value(:hostname) 
 
  command = 'ls -lQ /fslink/sysinfra/signatures/oracle/' + host_name + ' 2>/dev/null | grep -E "[[:graph:]]*\.xml\"" | awk \'$3 == "oracle" {print $9}\' | sed \'s/"//g\' | sort '
  output = %x[#{command}]
 
  if !output.empty?
   output.each_line.with_index do | li, index |
    ls_array[index] = li.strip
   end
  end

  ls_array

 end
end

