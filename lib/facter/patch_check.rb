Facter.add(:home_patch_list) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do 
  home_array = ['']
  count = 0 
  command = 'cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml 2>/dev/null | grep \'oradb::ora_home_db_\' | sed  "s/^oradb::ora_home_db_.*: \'\(.*\)\'/\1/" | sort -u'
  oratab_entries = %x[#{command}]
 
  if !oratab_entries.empty?
   oratab_entries.each_line do |li|
    home_path = li.strip
    command = 'su - oracle -c \'' + home_path + '/OPatch/opatch lsinventory -patch_id -oh ' + home_path + ' -invPtrLoc /etc/oraInst.loc 2>/dev/null\' | grep \' applied on \' |  awk -F\' \' \'{print $2}\''
    patch_entries = %x[#{command}]
    patch_list = ''
    patch_entries.each_line do |patch_id|
     patch_list = patch_list + '_' + patch_id.strip
    end
    if patch_list.empty?
     patch_list = '_'
    end
    home_array_entry = home_path + ':' + patch_list
    home_array[count] = home_array_entry
    count += 1
   end
  end
  home_array
 end
end
