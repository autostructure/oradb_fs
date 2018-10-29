####
# hostname_ebn_exists
#
####
Facter.add(:hostname_ebn_exists) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :db ]
 setcode do
  if Facter.value(:rman_setup_list) == [ '' ]
   0 #no touch files exists for rman setup
  else
   host_name = Facter.value(:hostname)
   command = "/bin/ping #{host_name}-ebn -c 1 2>/dev/null"
   ping_out = %x[#{command}]

   if !ping_out.empty?
    1 #hostname-ebn ping succeded
   else
    -1 #hostname-ebn ping failed
   end
  end
 end
end

