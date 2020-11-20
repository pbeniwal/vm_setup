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

# Install Kubernetes

sudo swapoff -a

sudo apt install -y apt-transport-https

sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

sudo bash -c 'echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'

sudo apt update

sudo apt install -y kubelet kubeadm kubectl

# Install Puppet

wget https://apt.puppetlabs.com/puppet6-release-bionic.deb

sudo dpkg -i puppet6-release-bionic.deb

sudo apt update

sudo apt install -y puppet-agent

sudo bash -c 'cat <<EOT >> /etc/puppetlabs/puppet/puppet.conf
[main]
certname = testnode01
server = puppet
environment = production
runinterval = 2m
EOT
'
