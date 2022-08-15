#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
install_tmp='/tmp/bt_install.pl'
pluginPath=/www/server/panel/plugin/nodejs

public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
	wget -O $public_file http://en.zpanel.cc/install/public.sh -T 5;
fi
. $public_file

download_Url=$NODE_URL


Install_nodejs()
{
	mkdir -p $pluginPath
	wget -O /www/server/panel/plugin/nodejs/icon.png $download_Url/install/plugin/nodejs_en/icon.png -T 5
	wget -O /www/server/panel/plugin/nodejs/nodejs_main.py $download_Url/install/plugin/nodejs_en/nodejs_main.py -T 5
	wget -O /www/server/panel/plugin/nodejs/index.html $download_Url/install/plugin/nodejs_en/index.html -T 5
	wget -O /www/server/panel/plugin/nodejs/info.json $download_Url/install/plugin/nodejs_en/info.json -T 5
	if [ -f /www/server/panel/plugin/nodejs/version_list.json ];then
		wget -O /www/server/panel/plugin/nodejs/version_list.json $download_Url/install/plugin/nodejs_en/version_list.json -T 5
	fi
	\cp -a -r /www/server/panel/plugin/nodejs/icon.png /www/server/panel/static/img/soft_ico/ico-nodejs.png
	echo '安装完成' > $install_tmp
}

Uninstall_nodejs()
{
	rm -rf $pluginPath
}


action=$1
if [ "${1}" == 'install' ];then
	Install_nodejs
else
	Uninstall_nodejs
fi
