####
# local_sig_ls
#
# returns an array of all signature files stored locally on the server
#
# each member of the array is a single filename: NAME.xml
#
####
Facter.add(:local_sig_ls) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do

  ls_array = ['']
 
  command = 'ls -lQ /opt/oracle/signatures 2>/dev/null | grep -E "[[:graph:]]*\.xml\"" | awk \'$3 == "oracle" {print $9}\' | sed \'s/"//g\' | sort ' 
  output = %x[#{command}]
 
  if !output.empty?
   output.each_line.with_index do | li, index |
    ls_array[index] = li.strip
   end
  end

  ls_array

 end
end

