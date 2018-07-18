Facter.add(:sid_associated_vestige_list) do
 confine :kernel => 'Linux'
 setcode do

  home_array = ['']

  command = "{(ls -ld /opt/oracle/oradata/data*/* 2>/dev/null | grep \"^d\" | awk '{print $9 }' | awk 'NF > 0'); " +
            "(ls -ld /opt/oracle/oradata/fra*/* 2>/dev/null | grep \"^d\" | awk '{print $9 }' | awk 'NF > 0'); " +
            "(ls -ld /opt/oracle/audit/* 2>/dev/null | grep \"^d\" | awk '{print $9 }' | awk 'NF > 0'); " +
            "(ls -ld /opt/oracle/admin/* 2>/dev/null | grep \"^d\" | awk '{print $9 }' | awk 'NF > 0'); " +
            "(ls -ld /opt/oracle/cfgtoollogs/dbca/* 2>/dev/null | grep \"^d\" | awk '{print $9 }' | awk 'NF > 0'); " +
            "(ls -ld /opt/oracle/diag/rdbms/* 2>/dev/null | grep \"^d\" | awk '{print $9 }' | awk 'NF > 0');} " +
            "| awk -F \"/\" '{print tolower($NF)\":\"$0}' | sort"

  output = %x[#{command}]

  if !output.empty?
   count = 0
   compare = ''
 
   output.each_line do |li|
 
    holding = li.strip.split(":")
 
    if compare == ''
     compare = holding[0]
     home_array[count] =  compare + ':' + holding[1]
    elsif holding[0] == compare
     home_array[count] = home_array[count] + ':' + holding[1]
    else
     count = count + 1
     compare = holding[0]
     home_array[count] = compare + ':' + holding[1]
    end
 
   end
  end

  home_array

 end
end

