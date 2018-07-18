Puppet::Functions.create_function(:return_sid_list) do
 dispatch :return_sid_list do
   param 'Array',   :search_list
   param 'String',  :home_number
   param 'String',  :home_path

   # return_type 'String'
 end

 def return_sid_list (search_list, home_number, home_path)

  search_list_compare_var = ''
  search_match = ['']

  if search_list.empty?
   search_list = ['']
  end

  if search_list != ['']

   holding = search_list[0].split(':')

   if holding[0] =~ /\/opt\/oracle\/.*/
    search_list_compare_var = home_path
   elsif holding[0] =~ /home_[0-9]*/ or holding[0] =~ /db_[0-9]*/
    search_list_compare_var = home_number
   elsif holding[0].length <= 8 and holding[0].length >= 1
   else
    fail
   end

   if search_list_compare_var != ''
    search_list.each do | value |
     holding = value.split(':')
     if holding[0] == search_list_compare_var
      search_match = holding.drop(1)
     end
    end
   else
    search_list.each.with_index do  | value, index |
     holding = value.split(':')
     search_match[index] = holding[0]
    end
   end
  end
  
  return search_match

 end
end

