require 'date'
require 'time'

Puppet::Functions.create_function(:patch_date_to_num) do
 dispatch :patch_date_to_num do
   param 'String',   :patch_date
   # return_type 'Array'
 end

 def patch_date_to_num (patch_date)

  the_date = Date.strptime(patch_date, "%Y_%m%b" )
  the_date2 = the_date.strftime("%Y%m")
  return the_date2
 
 end
end
