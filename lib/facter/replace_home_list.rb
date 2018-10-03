#/tmp/puppet_replace_db_NUM
Facter.add(:replace_home_list) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do
  
  command = 'ls -lQ /tmp | grep -E \"puppet_replace_db_[0-9]*\"$ | awk \'$3 == "oracle" {print $9}\' | awk -F_ \'{print $3"_"$4 }\''
  recover_db_entries = %x[#{command}]

  if recover_db_entries.empty?
   ['']
  else
   Array(recover_db_entries.gsub('"','').strip)
  end

 end
end

