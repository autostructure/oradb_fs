#/tmp/puppet_rman_db_NUM_SID
Facter.add(:rman_setup_list) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do

  rman_setup_array = ['']

  command = 'ls -lQ /tmp | grep -E \"puppet_rman_db_[0-9]*_[[:alpha:]]{1}[A-Za-z0-9_\$\#]{0\,7}\"$ | awk \'$3 == "oracle" {print $9}\' | sort'
  rman_db_entries = %x[#{command}]

  if !rman_db_entries.empty?
   count = 0
   compare = ''

   rman_db_entries.each_line do |li|

    holding = li[13..-1].strip
    home = holding.match('db_[0-9]*_')[0]
    sid = holding.gsub(/db_[0-9]*_/, '').chomp('"')
    home = home.chomp('_')

    if compare == ''
     compare = home 
     rman_setup_array[count] = compare + ':' + sid
    elsif home == compare
     rman_setup_array[count] = rman_setup_array[count] + ':' + sid
    else
     count = count + 1
     compare = home
     rman_setup_array[count] = compare + ':' + sid
    end

   end
  end

  rman_setup_array

 end
end

