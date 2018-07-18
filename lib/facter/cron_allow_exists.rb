Facter.add(:cron_allow_exists) do
 confine :kernel => 'Linux'
 setcode do

  command = 'ls /etc/cron.allow 2>/dev/null | wc -l'
  output = %x[#{command}]
 
  output.strip

 end
end

