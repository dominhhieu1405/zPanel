#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
install_tmp='/tmp/bt_install.pl'
public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
	wget -O $public_file http://en.zpanel.cc/install/public.sh -T 5;
fi
. $public_file
download_Url=$NODE_URL
pluginPath=/www/server/panel/plugin/anti_spam

set_hostname(){
  tmp=$(hostname|grep '\.')
  hostname=$(hostname)
  if [ "$tmp" == "" ];then
    hostnamectl --static set-hostname ${hostname}.localdomain
  fi
}

set_amavisd_default_conf(){
  if [ -f '/etc/redhat-release' ];then
    rm -f /etc/amavisd/amavisd.conf_bt
    mv /etc/amavisd/amavisd.conf /etc/amavisd/amavisd.conf_bt
    wget -O /etc/amavisd/amavisd.conf $download_Url/install/plugin/anti_spam/conf/centos/amavis/amavisd.conf -T 5
    sed -i 's/Wants=clamd@amavisd.service/#Wants=clamd@amavisd.service/' /usr/lib/systemd/system/amavisd.service
    systemctl daemon-reload
  else
    rm -rf /etc/amavis/conf.d_bt
    mv /etc/amavis/conf.d /etc/amavis/conf.d_bt
    mkdir -p /etc/amavis/conf.d
    cd /etc/amavis/conf.d
    wget -O /etc/amavis/conf.d/amavis.zip $download_Url/install/plugin/anti_spam/conf/ubuntu/amavis/amavis.zip -T 5
    unzip amavis.zip
    rm -f amavis.zip
  fi
}

set_spamassassin_default_conf(){
  if [ ! -f '/etc/redhat-release' ];then
    rm -f /etc/default/spamassassin_bt
    mv /etc/default/spamassassin /etc/default/spamassassin_bt
    wget -O /etc/default/spamassassin $download_Url/install/plugin/anti_spam/conf/ubuntu/spamassassin/spamassassin -T 5
    echo "updateing spamassassin db (may take a long time)..."
    sa-update
    if [ ! -f '/var/lib/spamassassin/3.004002/updates_spamassassin_org/10_default_prefs.cf' ];then
      wget -O /var/lib/spamassassin/3.004002/updates_spamassassin_org/update.tar.gz $download_Url/install/plugin/anti_spam/conf/ubuntu/spamassassin/update.tar.gz -T 5
      cd /var/lib/spamassassin/3.004002/updates_spamassassin_org/
      tar -zxvf update.tar.gz
    fi
    sa-update
  fi
}

update_spam_anti(){
  echo 'Installing script file...' > $install_tmp
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
    wget -O $pluginPath/anti_spam_main.py $download_Url/install/plugin/anti_spam/anti_spam_main.py -T 5
    wget -O $pluginPath/anti_spam_server.py $download_Url/install/plugin/anti_spam/anti_spam_server.py -T 5
    wget -O $pluginPath/index.html $download_Url/install/plugin/anti_spam/index.html -T 5
    wget -O $pluginPath/info.json $download_Url/install/plugin/anti_spam/info.json -T 5
    wget -O $pluginPath/icon.png $download_Url/install/plugin/anti_spam/icon.png -T 5
    wget -O /etc/init.d/anti_spam_service $download_Url/install/plugin/anti_spam/init.sh -T 5
	else
    wget -O $pluginPath/anti_spam_main.py $download_Url/install/plugin/anti_spam_en/anti_spam_main.py -T 5
    wget -O $pluginPath/anti_spam_server.py $download_Url/install/plugin/anti_spam_en/anti_spam_server.py -T 5
    wget -O $pluginPath/index.html $download_Url/install/plugin/anti_spam_en/index.html -T 5
    wget -O $pluginPath/info.json $download_Url/install/plugin/anti_spam_en/info.json -T 5
    wget -O $pluginPath/icon.png $download_Url/install/plugin/anti_spam_en/icon.png -T 5
    wget -O /etc/init.d/anti_spam_service $download_Url/install/plugin/anti_spam/init.sh -T 5
	fi
		echo ">>>>>>Start to update virus database"
	freshclam
	echo ">>>>>>Completion of update virus database"
}

Install_spam_anti()
{
  if [ -f '/etc/redhat-release' ];then
    cat /etc/redhat-release|grep "release 8"
    if [ "$?" -ne 0 ];then
      echo 7
    else
      yum install perl -y
      rpm -ivh $download_Url/install/plugin/anti_spam/perl-Digest-SHA1-2.13-23.el8.x86_64.rpm
      rpm -ivh $download_Url/install/plugin/anti_spam/perl-IO-stringy-2.111-9.el8.noarch.rpm
      rpm -ivh $download_Url/install/plugin/anti_spam/perl-common-sense-3.7.4-8.el8.x86_64.rpm
    fi
    yum install amavisd-new clamav clamav-devel clamd spamassassin -y
  else
    apt-get install amavisd-new -y
    apt-get install spamassassin clamav clamav-daemon -y
    apt-get install arj bzip2 cabextract cpio file gzip nomarch pax rar unrar unzip zip -y
    apt-get install razor pyzor dcc-client
  fi
  mkdir -p $pluginPath
	echo 'Installing script file...' > $install_tmp
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
    wget -O $pluginPath/anti_spam_main.py $download_Url/install/plugin/anti_spam/anti_spam_main.py -T 5
    wget -O $pluginPath/anti_spam_server.py $download_Url/install/plugin/anti_spam/anti_spam_server.py -T 5
    wget -O $pluginPath/index.html $download_Url/install/plugin/anti_spam/index.html -T 5
    wget -O $pluginPath/info.json $download_Url/install/plugin/anti_spam/info.json -T 5
    wget -O $pluginPath/icon.png $download_Url/install/plugin/anti_spam/icon.png -T 5
    wget -O /etc/init.d/anti_spam_service $download_Url/install/plugin/anti_spam/init.sh -T 5
	else
    wget -O $pluginPath/anti_spam_main.py $download_Url/install/plugin/anti_spam_en/anti_spam_main.py -T 5
    wget -O $pluginPath/anti_spam_server.py $download_Url/install/plugin/anti_spam_en/anti_spam_server.py -T 5
    wget -O $pluginPath/index.html $download_Url/install/plugin/anti_spam_en/index.html -T 5
    wget -O $pluginPath/info.json $download_Url/install/plugin/anti_spam_en/info.json -T 5
    wget -O $pluginPath/icon.png $download_Url/install/plugin/anti_spam_en/icon.png -T 5
    wget -O /etc/init.d/anti_spam_service $download_Url/install/plugin/anti_spam/init.sh -T 5
	fi
	chmod +x  /etc/init.d/anti_spam_service
	echo ">>>>>>Start to initialize virus database"
	freshclam
	echo ">>>>>>Completion of initializing virus database"
	set_amavisd_default_conf
	set_spamassassin_default_conf

	systemctl restart spamassassin
  if [ ! -f '/etc/redhat-release' ];then
    usermod -a -G amavis clamav
    chmod g+rx /var/lib/amavis/tmp/
	  systemctl restart amavis
	  systemctl restart clamav-daemon
	  systemctl restart clamav-freshclam
	  systemctl enable amavis
	  systemctl ebable clamav-daemon
	  systemctl ebable clamav-freshclam
	else
	  systemctl restart amavisd
	  systemctl stop clamd@amavisd.service
	  systemctl enable amavisd
	fi
	systemctl enable spamassassin
}

Uninstall_spam_anti()
{
  if [ ! -f '/etc/redhat-release' ];then
    systemctl stop amavis
    systemctl stop clamav-daemon
    systemctl stop clamav-freshclam
    systemctl disable amavis
    systemctl disable clamav-daemon
    systemctl disable clamav-freshclam
#    sudo apt remove amavisd-new clamav clamav-devel clamd spamassassin -y
  else
    systemctl stop amavisd
    systemctl stop clamd@amavisd.service
    systemctl stop spamassassin
    systemctl disable amavisd
    systemctl disable clamd@amavisd.service
    systemctl disable spamassassin
#    yum remove amavisd-new clamav clamav-devel clamd spamassassin -y
  fi

  rm -rf $pluginPath
}


action=$1
if [ "${1}" == 'install' ];then
  set_hostname
	Install_spam_anti
	/etc/init.d/anti_spam_service start
elif [ "${1}" == 'update' ];then
  update_spam_anti
else
	Uninstall_spam_anti
fi
