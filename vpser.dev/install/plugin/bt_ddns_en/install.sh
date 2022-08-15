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
pluginPath=/www/server/panel/plugin/bt_ddns


Install_ddns()
{
	en=''
	begin='正在安装脚本文件...'
	end='安装完成'
	grep "English" /www/server/panel/config/config.json >> /dev/null
	if [ "$?" -eq 0 ];then
		en='_en'
		begin='Installing script file...'
		end='The installation is complete'
	fi
	mkdir -p $pluginPath
	echo $begin > $install_tmp
	wget -O $pluginPath/bt_ddns_main.py $download_Url/install/plugin/bt_ddns$en/bt_ddns_main.py -T 5
	wget -O $pluginPath/index.html $download_Url/install/plugin/bt_ddns$en/index.html -T 5
	wget -O $pluginPath/info.json $download_Url/install/plugin/bt_ddns$en/info.json -T 5
	wget -O $pluginPath/icon.png $download_Url/install/plugin/bt_ddns$en/icon.png -T 5
	wget -O /etc/init.d/bt_ddns $download_Url/install/plugin/bt_ddns$en/bt_ddns.sh -T 5
	wget -O /lib/systemd/system/bt_ddns.service $download_Url/install/plugin/bt_ddns$en/bt_ddns.service -T 5
	\cp -a -r /www/server/panel/plugin/bt_ddns/icon.png /www/server/panel/BTPanel/static/img/soft_ico/ico-bt_ddns.png
	mkdir $pluginPath/dns
	touch $pluginPath/dns/__init__.py
	wget -O $pluginPath/dns/cloudflare.py $download_Url/install/plugin/bt_ddns$en/dns/cloudflare.py -T 5
	mkdir -p $pluginPath/config/zone
	chmod +x /etc/init.d/bt_ddns
	systemctl daemon-reload
	systemctl enable bt_ddns.service
	systemctl start bt_ddns.service
	echo $end > $install_tmp
}

Uninstall_ddns()
{
	rm -rf $pluginPath
}

if [ "${1}" == 'install' ];then
	Install_ddns
elif  [ "${1}" == 'update' ];then
	Install_ddns
elif [ "${1}" == 'uninstall' ];then
	Uninstall_ddns
fi
