####
# cron_allow_exists
#
# returns 0 or 1 based on the existence of /etc/cron.allow
#  1 exists
#  0 DNE
#
####
Facter.add(:cron_allow_exists) do
 confine :kernel => 'Linux'
 setcode do

  command = 'ls /etc/cron.allow 2>/dev/null | wc -l'
  output = %x[#{command}]
 
  output.strip

 end
end

