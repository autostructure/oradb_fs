Facter.add(:orapriv_hostname_exists) do
  confine :kernel => 'Linux'
  confine :"oradb_fs::ora_platform" => [ :oem, :db ]
  setcode do

  if Facter.value(:domain) == 'wrk.fs.usda.gov'
   area_domain = 'work'
  elsif Facter.value(:domain) == 'fdc.fs.usda.gov'
   area_domain = 'prod'
  else
   area_domain = 'fail'
  end

  if area_domain == 'fail'
   'fail'  #Area domain not defined
  else
   command = "df -k | grep /nfsroot/" + area_domain + "/orapriv/`hostname` | grep -v /nfsroot/" + area_domain + "/orapriv/`hostname`/ | awk '{print $6 }' | wc -l | /bin/awk '{if ($1==1) {print \"true\"} else {print \"false\"}}'"
   orapriv_hostname_exists = %x[#{command}]
   orapriv_hostname_exists.strip
 
  end
 end
end

