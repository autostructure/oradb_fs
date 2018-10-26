####
# db_archive_mode_list
#
# returns a hash of SID name and the value of LOG_MODE from v$database
#
####
Facter.add(:db_archive_mode_list) do
 confine :kernel => 'Linux'
 confine :"oradb_fs::ora_platform" => [ :oem, :db ]
 setcode do

  home_associated_running_db_list = Facter.value(:home_associated_running_db_list)

  archive_mode_list = Hash.new

  home_associated_running_db_list.each { |home_dbs|
   holding = home_dbs.split(':')
   home_path = holding[0]
   dbs = holding.drop(1)

   dbs.each { |db|

    command = "sqlplus -s /nolog <<-EOF
connect / as sysdba
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT LOG_MODE FROM SYS.V\\$DATABASE;
EXIT;
EOF"

    output =  `su - oracle -c 'export ORACLE_HOME="#{home_path}";export PATH="#{home_path}/bin:$PATH";export ORACLE_SID="#{db}";export LD_LIBRARY_PATH="#{home_path}/lib";#{command}'`
    archive_mode_list[db] = output.strip
   }
  }

  archive_mode_list
 end
end

