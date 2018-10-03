Facter.add(:puppet_run_db_1) do
  confine :kernel => 'Linux'
  confine :"oradb_fs::ora_platform" => [ :oem, :db ]
  setcode "ls -l /tmp/puppet_run_db_1 2>/dev/null | awk '{print $3}' | grep oracle | wc -l"
end

Facter.add(:puppet_run_db_2) do
  confine :kernel => 'Linux'
  confine :"oradb_fs::ora_platform" => [ :oem, :db ]
  setcode "ls -l /tmp/puppet_run_db_2 2>/dev/null | awk '{print $3}' | grep oracle | wc -l"
end

Facter.add(:puppet_run_db_3) do
  confine :kernel => 'Linux'
  confine :"oradb_fs::ora_platform" => [ :oem, :db ]
  setcode "ls -l /tmp/puppet_run_db_3 2>/dev/null | awk '{print $3}' | grep oracle | wc -l"
end

Facter.add(:puppet_run_db_4) do
  confine :kernel => 'Linux'
  confine :"oradb_fs::ora_platform" => [ :oem, :db ]
  setcode "ls -l /tmp/puppet_run_db_4 2>/dev/null | awk '{print $3}' | grep oracle | wc -l"
end

Facter.add(:puppet_run_db_5) do
  confine :kernel => 'Linux'
  confine :"oradb_fs::ora_platform" => [ :oem, :db ]
  setcode "ls -l /tmp/puppet_run_db_5 2>/dev/null | awk '{print $3}' | grep oracle | wc -l"
end

Facter.add(:puppet_run_db_6) do
  confine :kernel => 'Linux'
  confine :"oradb_fs::ora_platform" => [ :oem, :db ]
  setcode "ls -l /tmp/puppet_run_db_6 2>/dev/null | awk '{print $3}' | grep oracle | wc -l"
end


