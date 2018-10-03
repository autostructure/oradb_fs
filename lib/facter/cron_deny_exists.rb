####
# cron_deny_exists
#
# returns 0 or 1 based on the existence of /etc/cron.deny
#  1 exists
#  0 DNE
#
####
Facter.add(:cron_deny_exists) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do

  command = 'ls /etc/cron.deny 2>/dev/null | wc -l'
  output = %x[#{command}]
 
  output.strip

 end
end

