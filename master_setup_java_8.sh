#!/bin/bash

if [ -f myfile ]; then
       echo "The startup script has already run so skipping"
       exit 0
fi

touch myfile

sudo apt update

sudo apt -y upgrade

sudo apt -y install openjdk-8-jdk

sudo apt -y install maven

sudo sh -c 'echo `hostname -I`  puppet >> /etc/hosts'

# Installing Jenkins

wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -

sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

sudo apt update

sudo apt -y install jenkins

echo "sleeping for 30 secs"

sleep 30

sudo sh -c 'echo jenkins  ALL=\(ALL\) NOPASSWD:ALL >> /etc/sudoers'

sudo perl -p -i.bak -e "s{<installStateName>NEW</installStateName>}{<installStateName>RUNNING</installStateName>}" /var/lib/jenkins/config.xml

sudo cp -r jenkins/plugins/*  /var/lib/jenkins/plugins/

sudo cp jenkins/users/config.xml /var/lib/jenkins/users/admin_*/

sudo chown -R jenkins:jenkins /var/lib/jenkins/

sudo systemctl restart jenkins

# Installing tomcat

sudo useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat

wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.39/bin/apache-tomcat-9.0.39.tar.gz  -P /tmp

sudo tar xf /tmp/apache-tomcat-9*.tar.gz -C /opt/tomcat

sudo ln -s /opt/tomcat/apache-tomcat-9.0.39 /opt/tomcat/latest

sudo chown -RH tomcat:tomcat /opt/tomcat/latest

sudo sh -c 'chmod +x /opt/tomcat/latest/bin/*.sh'

sudo sh -c 'cp /opt/tomcat/latest/conf/server.xml /opt/tomcat/latest/conf/server.xml_bak; sed "s/8080/9090/g" /opt/tomcat/latest/conf/server.xml_bak > /opt/tomcat/latest/conf/server.xml'

sudo sh -c 'cat /opt/tomcat/latest/conf/tomcat-users.xml | sed '\''/\/tomcat-users/i  <role rolename="admin-gui"/> \n <role rolename="manager-gui"/> \n <role rolename="manager-script"/> \n <user username="admin" password="admin_password" roles="admin-gui,manager-gui"/> \n <user username="war-deployer" password="jenkins-tomcat-deploy" \n roles="manager-script" /> '\'' >  temp && mv temp /opt/tomcat/latest/conf/tomcat-users.xml'

sudo sh -c  'cat /opt/tomcat/latest/webapps/manager/META-INF/context.xml | sed "/CookieProcessor className/,/Manager/d" > temp && mv temp /opt/tomcat/latest/webapps/manager/META-INF/context.xml '

sudo bash -c 'cat <<EOT > /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat 9 servlet container
After=network.target
[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"
Environment="CATALINA_BASE=/opt/tomcat/latest"
Environment="CATALINA_HOME=/opt/tomcat/latest"
Environment="CATALINA_PID=/opt/tomcat/latest/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
ExecStart=/opt/tomcat/latest/bin/startup.sh
ExecStop=/opt/tomcat/latest/bin/shutdown.sh
[Install]
WantedBy=multi-user.target
EOT
'

sudo systemctl daemon-reload

sudo systemctl start tomcat

sudo systemctl enable tomcat

# Install Firefox

sudo apt install -y firefox

# Install Chrome

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

sudo apt -y install ./google-chrome-stable_current_amd64.deb

# Install Docker

sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose

sudo apt install -y docker-compose

# Install Kubernetes

sudo swapoff -a 

sudo apt install -y apt-transport-https

sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - 

sudo bash -c 'echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'

sudo apt update

sudo apt install -y kubelet kubeadm kubectl

sudo kubeadm config images pull

# sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# curl https://docs.projectcalico.org/manifests/calico.yaml -O

# kubectl apply -f calico.yaml

# Install Puppet

wget https://apt.puppetlabs.com/puppet6-release-bionic.deb 

wget https://apt.puppet.com/puppet-tools-release-bionic.deb

sudo dpkg -i puppet-tools-release-bionic.deb puppet6-release-bionic.deb 

sudo apt update

sudo apt install -y puppetserver pdk

sudo /opt/puppetlabs/bin/puppetserver ca setup

sudo systemctl start puppetserver

sudo systemctl enable puppetserver

sudo systemctl stop puppet

sudo systemctl disable puppet

# Install Ansible

#sudo apt-add-repository --yes --update ppa:ansible/ansible

sudo apt update

sudo apt -y install ansible

# Install Nagios

sudo apt install -y build-essential apache2 php php-gd libgd-dev unzip

sudo useradd nagios

sudo groupadd nagcmd

sudo usermod -a -G nagcmd nagios

sudo usermod -a -G nagios,nagcmd www-data

wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.6.tar.gz

tar -xzf nagios*.tar.gz

cd nagios-4.4.6

./configure --with-nagios-group=nagios --with-command-group=nagcmd

make all

make install

make install-commandmode

make install-init

make install-config

/usr/bin/install -c -m 644 sample-config/httpd.conf /etc/apache2/sites-available/nagios.conf

sudo cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/

sudo chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers

cd ..

wget https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz
tar -xzf nagios-plugins*.tar.gz

cd nagios-plugins-2.3.3

./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl

make

make install

sudo sh -c 'cp /usr/local/nagios/etc/nagios.cfg /usr/local/nagios/etc/nagios.cfg_bak ; sed "s/#cfg_dir=\/usr\/local\/nagios\/etc\/servers/cfg_dir=\/usr\/local\/nagios\/etc\/servers/g" /usr/local/nagios/etc/nagios.cfg_bak > /usr/local/nagios/etc/nagios.cfg'

sudo sh -c 'cp /usr/local/nagios/etc/nagios.cfg /usr/local/nagios/etc/nagios.cfg_bak1 ; sed "s/service_freshness_check_interval=60/service_freshness_check_interval=6/g" /usr/local/nagios/etc/nagios.cfg_bak1 > /usr/local/nagios/etc/nagios.cfg'

sudo sh -c 'cp /usr/local/nagios/etc/cgi.cfg /usr/local/nagios/etc/cgi.cfg_bak ; sed "s/refresh_rate=90/refresh_rate=5/g" /usr/local/nagios/etc/cgi.cfg_bak > /usr/local/nagios/etc/cgi.cfg'

sudo sh -c 'cp /usr/local/nagios/etc/objects/localhost.cfg /usr/local/nagios/etc/objects/localhost.cfg_bak ; sed "s/check_local_users\!20\!50/check_local_users\!2\!5/g" /usr/local/nagios/etc/objects/localhost.cfg_bak > /usr/local/nagios/etc/objects/localhost.cfg'

sudo mkdir -p /usr/local/nagios/etc/servers

sudo a2enmod rewrite

sudo a2enmod cgi

sudo ln -s /etc/apache2/sites-available/nagios.conf /etc/apache2/sites-enabled/

sudo apt install -y libxml-xpath-perl

sudo service apache2 restart

sudo service nagios restart

sudo systemctl enable nagios.service
