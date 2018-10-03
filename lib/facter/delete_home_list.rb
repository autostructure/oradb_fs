####
# delete_home_list
#
# returns an array of home variable sets that have the 'delete home' destructor enabled
# destructor is enabled by creating /tmp/puppet_deletehome_db_NUM as the Oracle user
#
####
Facter.add(:delete_home_list) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do
  
  delete_home_array = ['']

  command = 'ls -lQ /tmp | grep -E \"puppet_deletehome_db_[0-9]*\" | awk \'$3 == "oracle" {print $9}\' | sort'
  delete_home_entries = %x[#{command}]
  if !delete_home_entries.empty?
   delete_home_entries.each_line.with_index do | value, index |
     holding  = value.strip
    delete_home_array[index] = holding[19..-2]
   end
  end

  delete_home_array
 
 end
end

