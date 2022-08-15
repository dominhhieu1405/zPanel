#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
install_tmp='/tmp/bt_install.pl'
#public_file=/www/server/panel/install/public.sh
#if [ ! -f $public_file ];then
#	wget -O $public_file http://en.zpanel.cc/install/public.sh -T 5;
#fi
#. $public_file
py_v="/usr/bin/python"
pip_v="/usr/bin/pip"
if [ -d "/www/server/panel/pyenv" ];then
  py_v="/www/server/panel/pyenv/bin/python"
  pip_v="/www/server/panel/pyenv/bin/pip"
fi
download_Url=https://node.aapanel.com
mkdir /var/run/fail2ban

new_install()
{
if [ -f "/etc/redhat-release" ];then
	yum install fail2ban -y
fi
if [ ! -d "/etc/fail2ban" ];then
  ${pip_v} uninstall setuptools -y && ${pip_v} install setuptools==57.5.0
	wget -O /tmp/fail2ban.tar.gz $download_Url/install/plugin/fail2ban/fail2ban.tar.gz -T 5
	cd /tmp
	tar -zxf fail2ban.tar.gz
	cp /tmp/fail2ban/files/debian-initd /etc/init.d/fail2ban
	cd /tmp/fail2ban
	${py_v} setup.py install
	${pip_v} uninstall setuptools -y && ${pip_v} install setuptools
	rm -rf /tmp/fail2ban
	rm -f /usr/bin/fail2ban-client
	rm -f /usr/bin/fail2ban-server
	if [ ${py_v} != "/usr/bin/python" ];then
	  ln -s /www/server/panel/pyenv/bin/fail2ban-server /usr/bin/fail2ban-server
	  ln -s /www/server/panel/pyenv/bin/fail2ban-client /usr/bin/fail2ban-client
	else
	  ln -s /usr/local/bin/fail2ban-server /usr/bin/fail2ban-server
	  ln -s /usr/local/bin/fail2ban-client /usr/bin/fail2ban-client
	fi
fi
}

Install_fail2ban()
{
echo 'Installing script files...' > $install_tmp
mkdir -p /www/server/panel/plugin/fail2ban/cdn

cd /tmp
if [ -f '/usr/bin/yum' ];then
	yum install git -y
	yum install rsyslog -y
else
	apt install git -y
	apt install rsyslog -y
fi
#if [ ! -d "/etc/fail2ban/" ];then
new_install
if [ ! -f "/usr/bin/fail2ban-client" ];then
  new_install
fi
#fi
#修改sock和pid位置
sed -i "s/pidfile\s=.*/pidfile = \/www\/server\/panel\/plugin\/fail2ban\/fail2ban\.pid/g" /etc/fail2ban/fail2ban.conf
sed -i "s/socket\s=\s\/.*/socket = \/www\/server\/panel\/plugin\/fail2ban\/fail2ban\.sock/g" /etc/fail2ban/fail2ban.conf

grep "English" /www/server/panel/config/config.json
if [ "$?" -ne 0 ];then
	wget -O /www/server/panel/plugin/fail2ban/fail2ban_main.py $download_Url/install/plugin/fail2ban/fail2ban_main.py -T 5
	wget -O /www/server/panel/plugin/fail2ban/index.html $download_Url/install/plugin/fail2ban/index.html -T 5
	wget -O /www/server/panel/plugin/fail2ban/info.json $download_Url/install/plugin/fail2ban/info.json -T 5
	wget -O /www/server/panel/plugin/fail2ban/icon.png $download_Url/install/plugin/fail2ban/icon.png -T 5
	if [ ! -f "/etc/fail2ban/jail.local" ];then
		wget -O /etc/fail2ban/jail.local $download_Url/install/plugin/fail2ban/jail.local -T 5
	fi
	wget -O /lib/systemd/system/fail2ban.service $download_Url/install/plugin/fail2ban/fail2ban.service -T 5
else
	wget -O /www/server/panel/plugin/fail2ban/fail2ban_main.py $download_Url/install/plugin/fail2ban_en/fail2ban_main.py -T 5
	wget -O /www/server/panel/plugin/fail2ban/index.html $download_Url/install/plugin/fail2ban_en/index.html -T 5
	wget -O /www/server/panel/plugin/fail2ban/info.json $download_Url/install/plugin/fail2ban_en/info.json -T 5
	wget -O /www/server/panel/plugin/fail2ban/icon.png $download_Url/install/plugin/fail2ban_en/icon.png -T 5
	wget -O /www/server/panel/plugin/fail2ban/cdn/cloudflare.py $download_Url/install/plugin/fail2ban_en/cdn/cloudflare.py -T 5
	if [ ! -f "/etc/fail2ban/jail.local" ];then
		wget -O /etc/fail2ban/jail.local $download_Url/install/plugin/fail2ban_en/jail.local -T 5
	fi
	wget -O /lib/systemd/system/fail2ban.service $download_Url/install/plugin/fail2ban_en/fail2ban.service -T 5
fi

#检查端口
sshport=`grep -v "#" /etc/ssh/sshd_config |grep "Port"|awk '{print $2}'|tr "\n" ","`
sshport=${sshport%?}
if [ "$sshport" = "" ];then
  sshport="22"
  sed -i "s/port = 22/port = $sshport/g" /etc/fail2ban/jail.local
else
  sed -i "s/port = 22/port = $sshport/g" /etc/fail2ban/jail.local
fi
ftpport="21"
if [ -f "/www/server/pure-ftpd/etc/pure-ftpd.conf" ];then
ftpport=`grep -v "#" /www/server/pure-ftpd/etc/pure-ftpd.conf|grep Bind|awk -F "," '{print $2}'`
if [ "$ftpport" = "" ];then
  ftpport="21"
  sed -i "s/port = 21/port = $ftpport/g" /etc/fail2ban/jail.local
else
  sed -i "s/port = 21/port = $ftpport/g" /etc/fail2ban/jail.local
fi
fi

jsonconf="{\"sshd\": {\"maxretry\": 5, \"findtime\": 300, \"act\": \"true\", \"port\": \"$sshport\", \"dir\": \"\", \"bantime\": 86400},\"ftpd\": {\"maxretry\": 5, \"findtime\": 300, \"act\": \"true\", \"port\": $ftpport, \"dir\": \"\", \"bantime\": 86400}}"
if [ ! -f "/www/server/panel/plugin/fail2ban/config.json" ];then
	echo $jsonconf > /www/server/panel/plugin/fail2ban/config.json
fi

#设置安全日志路径
if [ -f "/var/log/auth.log" ];then
  slp="\/var\/log\/auth.log"
  sed -i "s/\/var\/log\/secure/$slp/g" /etc/fail2ban/jail.local
fi

#使用UFW规则
if [ ! -f "/etc/redhat-release" ];then
    sed -i "s/banaction = firewallcmd-ipset/banaction = ufw/g" /etc/fail2ban/jail.local
fi
#设置messages日志
grep -v "#" /etc/rsyslog.conf |grep "messages"
if [ "$?" -ne 0 ];then
echo "*.info;mail.none;authpriv.none;cron.none                /var/log/messages" >> /etc/rsyslog.conf
systemctl restart rsyslog
fi
#设置ubuntu系统日志
if [ ! -f '/var/log/messages' ];then
	if [ -f '/var/log/syslog' ];then
		echo "Setting syslog..."
		sed -i "s/messages/syslog/g" /etc/fail2ban/jail.local
	fi
fi
#fail2ban-client start
systemctl restart rsyslog
systemctl unmask fail2ban
systemctl daemon-reload
systemctl restart fail2ban
systemctl enable fail2ban

echo 'The installation is complete' > $install_tmp
}

Uninstall_fail2ban()
{
	fail2ban-client unban --all
	fail2ban-client stop
	rm -rf /etc/fail2ban
	rm -f /etc/init.d/fail2ban
	rm -f /lib/systemd/system/fail2ban.service
	rm -rf /www/server/panel/plugin/fail2ban
	rm -f /usr/bin/fail2ban-client
	rm -f /usr/bin/fail2ban-server
	rm -f /var/log/fail2ban.log
if [ -f '/usr/bin/yum' ];then
	yum remove fail2ban* -y
else
	apt remove fail2ban* -y
fi

	echo 'Uninstall complete' > $install_tmp
}


action=$1
if [ "${1}" == 'install' ];then
	Install_fail2ban
	echo '1' > /www/server/panel/data/reload.pl
else
	Uninstall_fail2ban
fi
