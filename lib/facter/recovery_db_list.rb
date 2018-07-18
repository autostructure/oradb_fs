#/tmp/puppet_recover_db_NUM_SID
Facter.add(:recovery_db_list) do
 confine :kernel => 'Linux'
 setcode do

  recover_db_array = ['']

  command = 'ls -lQ /tmp | grep -E \"puppet_recover_db_[0-9]*_[[:alpha:]]{1}[A-Za-z0-9_\$\#]{0\,7}\"$ | awk \'$3 == "oracle" {print $9}\' | sort'
  recover_db_entries = %x[#{command}]

  if !recover_db_entries.empty?
   count = 0
   compare = ''

   recover_db_entries.each_line do |li|

    holding = li[16..-1].strip
    home = holding.match('db_[0-9]*_')[0]
    sid = holding.gsub(/db_[0-9]*_/, '').chomp('"')
    home = home.chomp('_')

    if compare == ''
     compare = home 
     recover_db_array[count] = compare + ':' + sid
    elsif home == compare
     recover_db_array[count] = recover_db_array[count] + ':' + sid
    else
     count = count + 1
     compare = home
     recover_db_array[count] = compare + ':' + sid
    end

   end
  end

  recover_db_array

 end
end

