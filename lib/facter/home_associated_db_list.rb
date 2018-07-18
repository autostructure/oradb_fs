Facter.add(:home_associated_db_list) do
 confine :kernel => 'Linux'
 setcode do

  home_array = ['']

  command = 'cat /etc/oratab 2>/dev/null| grep -v \# | awk NF | sort -t: -k2'
  oratab_entries = %x[#{command}]

  if !oratab_entries.empty?
   count = 0
   compare = ''
 
   oratab_entries.each_line do |li|
 
    holding = li.split(":")
 
    if compare == ''
     compare = holding[1]
     home_array[count] = holding[1] + ':' + holding[0]
    elsif holding[1] == compare
     home_array[count] = home_array[count] + ':' + holding[0]
    else
     count = count + 1
     compare = holding[1]
     home_array[count] = holding[1] + ':' + holding[0]
    end
   end
  end
 
  home_array

 end
end

