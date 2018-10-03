####
# packages_exist
#
####
Facter.add(:packages_exist) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do

  rpm_array = [ '0', '0', '0', '0' ]
  install = ''
  update = ''
  array_out = [ '', '' ]

  command = 'rpm -qa | grep -E \'^ksh-[0-9].*\.x86_64|^libstdc\+\+-[0-9].*\.x86_64|^libstdc\+\+-[0-9].*\.i686|^libgcc-[0-9].*\.i686\''
  output = %x[#{command}]

  if !output.empty?
   output.each_line do | li |
    if li =~ /ksh-[0-9].*\.x86_64/
     rpm_array[0] = '1'
    elsif li =~ /libstdc\+\+-[0-9].*\.x86_64/
     rpm_array[1] = '1'
    elsif li =~ /libstdc\+\+-[0-9].*\.i686/
     rpm_array[2] = '1'
    elsif li =~ /libgcc-[0-9].*\.i686/
     rpm_array[3] = '1'
    end
   end
  end

  if rpm_array[0] == '1'
   if update == ''
    update = 'ksh.x86_64'
   else
    update = update + ' ksh.x86_64'
   end
  else
   if install == ''
    install = 'ksh.x86_64'
   else
    install = install + ' ksh.x86_64'
   end
  end

  if rpm_array[1] == '1'
   if update == ''
    update = 'libstdc++.x86_64'
   else
    update = update + ' libstdc++.x86_64'
   end
  else
   if install == ''
    install = 'libstdc++.x86_64'
   else
    install = install + ' libstdc++.x86_64'
   end
  end

  if rpm_array[2] == '1'
   if update == ''
    update = 'libstdc++.i686'
   else
    update = update + ' libstdc++.i686'
   end
  else
   if install == ''
    install = 'libstdc++.i686'
   else
    install = install + ' libstdc++.i686'
   end
  end

  if rpm_array[3] == '1'
   if update == ''
    update = 'libgcc.i686'
   else
    update = update + ' libgcc.i686'
   end
  else
   if install == ''
    install = 'libgcc.i686'
   else
    install = install + ' libgcc.i686'
   end
  end

  array_out[0] = install
  array_out[1] = update

  array_out

 end
end

