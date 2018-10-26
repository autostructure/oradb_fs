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
  homes[1] = Facter.value(:"oradb_fs::ora_db_info_list_db_2")
  homes[2] = Facter.value(:"oradb_fs::ora_db_info_list_db_3")
  homes[3] = Facter.value(:"oradb_fs::ora_db_info_list_db_4")
  homes[4] = Facter.value(:"oradb_fs::ora_db_info_list_db_5")
  homes[5] = Facter.value(:"oradb_fs::ora_db_info_list_db_6")

  homes.each { |db_info_list|
   if db_info_list != nil
    db_info_list.each { |db_info|
     holding = db_info.split(':')
     if holding[-1] != 'rman'
      sid_exclude_list = sid_exclude_list + holding[0] + '|'
     end
    }
   end
  }

  sid_exclude_list.chomp('|')

 end
end

