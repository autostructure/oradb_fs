####
# hostname_ebn_exists
#
# returns 0 or 1 based on the existence of /usr/openv/netbackup/bin/libobk.so64
#  >0 exists
#  0  DNE
#
####
Facter.add(:hostname_ebn_exists) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do

  command = 'ping -c 1 ${HOSTNAME}-ebn 2>/dev/null | wc -l'
  output = %x[#{command}]

  output.strip

 end
end

