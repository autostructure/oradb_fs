Facter.add(:cron_deny_exists) do
 confine :kernel => 'Linux'
 setcode do

  command = 'ls /etc/cron.deny 2>/dev/null | wc -l'
  output = %x[#{command}]
 
  output.strip

 end
end

