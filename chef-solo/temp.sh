#!/bin/bash

export CURRENT_HOSTNAME=${HOSTNAME}
export CURRENT_INTERNAL_IP=`ifconfig | grep 'inet addr:' | grep -v '127.0.0.1' | cut -d: -f2 | awk '{print $1}'`
export SOFTWARE_BASE_URL="http://10.183.33.173/dev-setup"

# Removes the assignment of the Rackspace internal static IP address to the hostname and
# replaces with the static internal IP that we can use. The original configuration
# causes issues with some applications (CQ for sure).
function setupHostsFile {
  sed "/.*${CURRENT_HOSTNAME}$/d" /etc/hosts > /tmp/hosts
  echo "${CURRENT_INTERNAL_IP} ${CURRENT_HOSTNAME}" >> /tmp/hosts
  mv -f /tmp/hosts /etc/hosts
}

# NOTE: This install requires human intervention to accept the stupid Java license.
function setupJdk {
  JAVA_INSTALL=jdk-6u25-linux-x64-rpm.bin
  cd /opt
  wget ${SOFTWARE_BASE_URL}/java/${JAVA_INSTALL}
  chmod +x ${JAVA_INSTALL}
  ./${JAVA_INSTALL}

  # remove the extra crap that this creates
  rm -rf jdk* sun*
  ln -s /usr/java/jdk1.6.0_25 /opt/jdk6
}

# Update time zone on server to PST.
function setupTimezone {
cat > /etc/sysconfig/clock <<EOF
ZONE="America/Los_Angeles"
UTC=true
ARC=false
EOF

  ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
}

function setupCq {
  if [[ ${HOSTNAME} == *-author* ]]; then
    CQ_INSTANCE_TYPE=author
    CQ_INSTANCE_PORT=5502
  elif [[ ${HOSTNAME} == *-publish* ]]; then
    CQ_INSTANCE_TYPE=publish
    CQ_INSTANCE_PORT=5503
  else
    echo "Cannot determine CQ instance type. Hostname is [${HOSTNAME}] and does not contain 'author' or 'publish'."
    exit 1
  fi

  ENVIRONMENT_TYPE=`expr "${HOSTNAME}" : '\(.[A-Z]*\)'`
  BASE_URL=http://10.183.33.173/dev-setup/cq
  CQ_HOME=/opt/cq/${CQ_INSTANCE_TYPE}

  wget ${BASE_URL}/init.d.cq
  mv init.d.cq /etc/init.d/cq
  chmod +x /etc/init.d/cq
 
  mkdir -p /opt/cq-5.4
  ln -s /opt/cq-5.4 /opt/cq
  mkdir ${CQ_HOME}

  cd ${CQ_HOME}
  wget ${BASE_URL}/cq-quickstart-5.4.0.jar
  wget ${BASE_URL}/license.properties
  mv cq-quickstart-5.4.0.jar cq5-${CQ_INSTANCE_TYPE}-${CQ_INSTANCE_PORT}.jar
  java -jar cq5-${CQ_INSTANCE_TYPE}-${CQ_INSTANCE_PORT}.jar -unpack

  SLING_PROPERTIES=${CQ_HOME}/crx-quickstart/launchpad/sling.properties
  echo "sling.jcrinstall.folder.name.regexp=.*/(install|config)(.${CQ_INSTANCE_TYPE}|.${ENVIRONMENT_TYPE})?$" >> ${SLING_PROPERTIES}
  echo "sling.run.modes=${CQ_INSTANCE_TYPE},${ENVIRONMENT_TYPE}" >> ${SLING_PROPERTIES}
 
  groupadd cq
  # the init script wants the user to be able to log in... can we change that? and should we have a home directory for the user? there's a warning about that as well from the init script.
  #useradd -g cq -s /sbin/nologin -r cq
  useradd -g cq cq
  chown -R cq:cq /opt/cq /opt/cq-5.4
 
  # CQ requires ulimit to be >= 8192 - TODO: Do we need this?
  ulimit -n 8192
 
  chkconfig --add cq
  chkconfig cq on
 
  # to start server instance (Note that the first startup takes around 7 mins on a VM with 4GB RAM)
  /etc/init.d/cq start
}

function setupTomcat {
  # install tomcat
  TOMCAT_INSTALL=apache-tomcat-7.0.23.tar.gz
  wget ${SOFTWARE_BASE_URL}/tomcat/${TOMCAT_INSTALL}
  tar xvf ${TOMCAT_INSTALL} -C /opt
  rm -f ${TOMCAT_INSTALL}
  ln -s /opt/apache-tomcat-7.0.23 /opt/tomcat

  # for non-prod Tomcat installs
  wget ${SOFTWARE_BASE_URL}/tomcat/tomcat-users-non-prod.xml
  mv -f tomcat-users-non-prod.xml /opt/tomcat/conf/tomcat-users.xml

  wget ${SOFTWARE_BASE_URL}/tomcat/setenv.sh
  mv -f setenv.sh /opt/tomcat/bin/setenv.sh

  # set up tomcat user to run tomcat
  groupadd tomcat
  useradd -g tomcat tomcat
  chown -R tomcat:tomcat /opt/tomcat /opt/apache-tomcat-7.0.23

  # set up init script to start tomcat when server reboots
  wget ${SOFTWARE_BASE_URL}/tomcat/init.d.tomcat
  mv init.d.tomcat /etc/init.d/tomcat
  chmod +x /etc/init.d/tomcat
  chkconfig --add tomcat
  chkconfig tomcat on

  # start server
  /etc/init.d/tomcat start
}

function setupApacheHttpForAuthor {
  CQ_AUTHOR_INSTANCE_HOST=${1}
  CQ_AUTHOR_INSTANCE_PORT=${2}

  yum install httpd.x86_64 -y

cat >> /etc/httpd/conf/httpd.conf <<EOF
ProxyRequests Off
 
<Proxy *>
Order deny,allow
Allow from all
</Proxy>
 
ProxyPass / http://${CQ_AUTHOR_INSTANCE_HOST}:${CQ_AUTHOR_INSTANCE_PORT}/
ProxyPassReverse / http://${CQ_AUTHOR_INSTANCE_HOST}:${CQ_AUTHOR_INSTANCE_PORT}/
EOF

  chkconfig --add httpd
  chkconfig httpd on

  # Start Apache Web Server
  /etc/init.d/httpd start
}

function setupApacheHttpForPublish {
  CQ_PUBLISH_INSTANCE_HOST=${1}
  CQ_PUBLISH_INSTANCE_PORT=${2}

  yum install httpd.x86_64 -y

  # Set up variables to replace placeholders in config files
  WEB_ROOT=/var/www/html
  APACHE_ROOT=/etc/httpd
  APACHE_LIB_ROOT=${APACHE_ROOT}/modules
  PUBLISH_HOSTNAME=${CQ_PUBLISH_INSTANCE_HOST}
  PUBLISH_PORT=${CQ_PUBLISH_INSTANCE_PORT}
  DISPATCHER_DIR=$APACHE_ROOT/dispatcher
  DISPATCHER_LOGS_DIR=$DISPATCHER_DIR/logs

  # Create dispatcher & log directories
  mkdir -p $DISPATCHER_LOGS_DIR

  # Subsitute placeholders and place dispatcher config into dispatcher directory
  cd /tmp
  wget http://10.183.33.173/dev-setup/dispatcher/dispatcher.any
  sed -e 's/$PUBLISH_HOSTNAME/'$PUBLISH_HOSTNAME'/' -e 's/$PUBLISH_PORT/'$PUBLISH_PORT'/' -e 's#$WEB_ROOT#'$WEB_ROOT'#' < /tmp/dispatcher.any > $DISPATCHER_DIR/dispatcher.any

  # Copy modules into the apache libs directory
  wget http://10.183.33.173/dev-setup/dispatcher/dispatcher-apache2.2-linux-x86-64-4.1.0.tgz
  tar xvf dispatcher-apache2.2-linux-x86-64-4.1.0.tgz
  cp modules/dispatcher-apache2.2-4.1.0.so $APACHE_LIB_ROOT
  ln -s $APACHE_LIB_ROOT/dispatcher-apache2.2-4.1.0.so $APACHE_LIB_ROOT/mod_dispatcher.so

  # Subsitute placeholders and place httpd.config into Apache root directory
  cd /tmp
  wget http://10.183.33.173/dev-setup/dispatcher/httpd.conf
  sed -e 's#$DISPATCHER_DIR#'$DISPATCHER_DIR'#' -e 's#$DISPATCHER_LOGS_DIR#'$DISPATCHER_LOGS_DIR'#' -e 's#$APACHE_ROOT#'$APACHE_ROOT'#' -e 's#${WEB_ROOT}#'${WEB_ROOT}'#' < /tmp/httpd.conf > $APACHE_ROOT/conf/httpd.conf

  # Change owner to apache daemon
  chown -R apache:apache $WEB_ROOT

  # Set the appropriate permissions so that the _www user can write, without giving unnecessary permissions to everyone else:
  chmod -R 755 $WEB_ROOT

  # cat dispatcher/conf/httpd.conf.dispatcher >> /etc/apache2/http.conf

  chkconfig --add httpd
  chkconfig httpd on

  # Start Apache Web Server
  /etc/init.d/httpd start
}

