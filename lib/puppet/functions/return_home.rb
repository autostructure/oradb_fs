Puppet::Functions.create_function(:return_home) do
 dispatch :return_home do
   param 'Array',   :search_list
   param 'String',  :home_number
   param 'String',  :home_path
   param 'String',  :return_type
   # return_type 'String'
 end

 def return_home (search_list, home_number, home_path, return_type)

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
   else
    fail
   end

   search_list.each do | value |
    holding = value.split(':')
    if holding[0] == search_list_compare_var
     if return_type == 'P'
      search_match[0] = home_path
      return search_match
     elsif return_type == 'N'
      search_match[0] = home_number
      return search_match
     else
      fail
     end
    end
   end

  end
  
  return search_match

 end
end
