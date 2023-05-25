#!/bin/bash
wget https://ecs-instance-driver.obs.cn-north-1.myhuaweicloud.com/datadisk/LinuxVMDataDiskAutoInitialize.sh
chmod +x LinuxVMDataDiskAutoInitialize.sh
yum -y install expect
/usr/bin/expect <<EOF
spawn ./LinuxVMDataDiskAutoInitialize.sh
expect "Step 3: Please choose the dis(e.g: /dev/vdb and q to quit):"
send "/dev/vdb\n"
expect "Please enter a location to mount (e.g: /mnt/data):"
send "/data_disk\n"
expect eof
EOF
rm -rf LinuxVMDataDiskAutoInitialize.sh
wget -P /data_disk/package https://documentation-samples.obs.cn-north-4.myhuaweicloud.com/solution-as-code-publicbucket/solution-as-code-moudle/deploy-a-highly-available-mongodb/open-source-software/mongodb-linux-x86_64-rhel70-5.0.7.tgz
tar -zxvf /data_disk/package/mongodb-linux-x86_64-rhel70-5.0.7.tgz -C /data_disk/package/
mv /data_disk/package/mongodb-linux-x86_64-rhel70-5.0.7 /data_disk/package/mongodb
ln -s /data_disk/package/mongodb/bin/mongo /usr/local/bin/mongo
mkdir /data_disk/mongodb
echo "net:" >> /data_disk/mongodb/mongo.conf
echo "  port: 27017" >> /data_disk/mongodb/mongo.conf
echo "  bindIp: 0.0.0.0" >> /data_disk/mongodb/mongo.conf
echo "systemLog:" >> /data_disk/mongodb/mongo.conf
echo "  destination: file" >> /data_disk/mongodb/mongo.conf
echo '  path: "/opt/mongodbdata/mongod.log"' >> /data_disk/mongodb/mongo.conf
echo "  logAppend: true" >> /data_disk/mongodb/mongo.conf
echo "storage:" >> /data_disk/mongodb/mongo.conf
echo "  journal:" >> /data_disk/mongodb/mongo.conf
echo "    enabled: true" >> /data_disk/mongodb/mongo.conf
echo "  dbPath: /opt/mongodbdata" >> /data_disk/mongodb/mongo.conf
echo "setParameter:" >> /data_disk/mongodb/mongo.conf
echo "  enableLocalhostAuthBypass: true" >> /data_disk/mongodb/mongo.conf
echo "processManagement:" >> /data_disk/mongodb/mongo.conf
echo "  fork: true" >> /data_disk/mongodb/mongo.conf
echo '  pidFilePath: "/opt/mongodbdata/mongod.pid"' >> /data_disk/mongodb/mongo.conf
mkdir /opt/mongodbdata
/data_disk/package/mongodb/bin/mongod -f /data_disk/mongodb/mongo.conf
yum -y install expect
/usr/bin/expect <<EOF
spawn mongo
expect "> "
send "use admin;\r"
expect "> "
send "db.createRole({role:'sysadmin', roles:\[\], privileges:\[{resource:{anyResource:true}, actions:\['anyAction'\]}\]});\r"
expect "> "
send "db.createUser({user:'root', pwd:'$1', roles:\[{role:'sysadmin', db:'admin'}\]});\r"
expect "> "
send "exit\r"
expect eof
EOF
/usr/bin/expect <<EOF
spawn mongo -uroot -p$1 --authenticationDatabase "admin"
expect ">"
send "show dbs;\r"
expect "> "
send "exit\r"
expect eof
exit
EOF
echo "replication:" >> /data_disk/mongodb/mongo.conf
echo "   replSetName: CrystalTest" >> /data_disk/mongodb/mongo.conf
/data_disk/package/mongodb/bin/mongod --shutdown -f /data_disk/mongodb/mongo.conf
/data_disk/package/mongodb/bin/mongod -f /data_disk/mongodb/mongo.conf