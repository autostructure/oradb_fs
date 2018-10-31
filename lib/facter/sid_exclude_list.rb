####
# sid_exclude_list
#
####
####
# sid_exclude_list
#
####
Facter.add(:sid_exclude_list) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do

  sid_exclude_list = ''
  server_sid_info = [ '' ]
  homes = [ '' ]

  homes[0] = Facter.value(:"oradb_fs::ora_db_info_list_db_1")
  if homes[0].nil? or homes[0] == ['']
   homes[0] = '0'
  end
  homes[1] = Facter.value(:"oradb_fs::ora_db_info_list_db_2")
  if homes[1].nil? or homes[1] == ['']
   homes[1] = '0'
  end
  homes[2] = Facter.value(:"oradb_fs::ora_db_info_list_db_3")
  if homes[2].nil? or homes[2] == ['']
   homes[2] = '0'
  end
  homes[3] = Facter.value(:"oradb_fs::ora_db_info_list_db_4")
  if homes[3].nil? or homes[3] == ['']
   homes[3] = '0'
  end
  homes[4] = Facter.value(:"oradb_fs::ora_db_info_list_db_5")
  if homes[4].nil? or homes[4] == ['']
   homes[4] = '0'
  end
  homes[5] = Facter.value(:"oradb_fs::ora_db_info_list_db_6")
  if homes[5].nil? or homes[5] == ['']
   homes[5] = '0'
  end

  homes.each_with_index { |db_info_list,index|
   if db_info_list != '0'
    db_info_list.each { |db_info|
     holding = db_info.split(':')
     if holding[-1] != 'rman' and holding[0] != 'yzzzzzzz'
      sid_exclude_list = sid_exclude_list + holding[0] + '|'
     end
    }
   end
  }

  sid_exclude_list.chomp('|')

 end
end

