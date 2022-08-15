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

Install_webhook()
{
	mkdir -p /www/server/panel/plugin/webhook
	echo '正在安装脚本文件...' > $install_tmp
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
		wget -O /www/server/panel/plugin/webhook/webhook_main.py $download_Url/install/plugin/webhook/webhook_main.py -T 5
		wget -O /www/server/panel/plugin/webhook/index.html $download_Url/install/plugin/webhook/index.html -T 5
		wget -O /www/server/panel/plugin/webhook/info.json $download_Url/install/plugin/webhook/info.json -T 5
		if [ ! -f /www/server/panel/plugin/webhook/list.json ];then
			wget -O /www/server/panel/plugin/webhook/list.json $download_Url/install/plugin/webhook/list.json -T 5
		fi
		wget -O /www/server/panel/plugin/webhook/icon.png $download_Url/install/plugin/webhook/icon.png -T 5
	else
		wget -O /www/server/panel/plugin/webhook/webhook_main.py $download_Url/install/plugin/webhook_en/webhook_main.py -T 5
		wget -O /www/server/panel/plugin/webhook/index.html $download_Url/install/plugin/webhook_en/index.html -T 5
		wget -O /www/server/panel/plugin/webhook/info.json $download_Url/install/plugin/webhook_en/info.json -T 5
		if [ ! -f /www/server/panel/plugin/webhook/list.json ];then
			wget -O /www/server/panel/plugin/webhook/list.json $download_Url/install/plugin/webhook_en/list.json -T 5
		fi
		wget -O /www/server/panel/plugin/webhook/icon.png $download_Url/install/plugin/webhook_en/icon.png -T 5
	fi
	echo '安装完成' > $install_tmp
}

Uninstall_webhook()
{
	rm -rf /www/server/panel/plugin/webhook
}


action=$1
if [ "${1}" == 'install' ];then
	Install_webhook
else
	Uninstall_webhook
fi
