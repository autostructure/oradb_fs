Install:  Run as user oracle:  something.sh
          Run as root:         something.sh

Create tar file
Then, run Puppet's (rubygem's) fpm to create the rpm
cd /fslink/sysinfra/oracle/downloads/rman/12.2/rcat_12.2.SI.tar.dir
/bin/rm rcat_12.2.SI.tar
/bin/mv ../rcat_12.2.SI.tar /tmp
tar -cpzf ../rcat_12.2.SI.tar ./tmp/rcat_12.2.0
ln -s ../rcat_12.2.SI.tar .

/bin/rm rn-ora_rman-1.1-1.x86_64.rpm
/bin/mv ../rn-ora_rman-1.1-1.x86_64.rpm /tmp
sudo /opt/puppetlabs/puppet/bin/gem install fpm
sudo yum whatprovides rpmbuild --disablerepo=pe_repo,pc_repo
sudo yum install rpm-build --disablerepo=pe_repo,pc_repo
/opt/puppetlabs/puppet/bin/fpm -s tar -t rpm --name rn-ora_rman --version 1.1 --after-install ./tmp/rcat_12.2.0/meta_rpm_after-install.sh --before-remove ./tmp/rcat_12.2.0/meta_rpm_before-remove_wrapper.sh ../rcat_12.2.SI.tar; /bin/mv rn-ora_rman-1.1-1.x86_64.rpm ..
#Expected Results:  Created package {:path=>"rn-ora_rman-1.1-1.x86_64.rpm"}

