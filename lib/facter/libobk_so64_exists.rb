####
# libobk_so64_exists
#
# returns 0 or 1 based on the existence of /usr/openv/netbackup/bin/libobk.so64
#  1 exists
#  0 DNE
#
####
Facter.add(:libobk_so64_exists) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do

  command = 'ls /usr/openv/netbackup/bin/libobk.so64 2>/dev/null | wc -l'
  output = %x[#{command}]

  output.strip

 end
end

