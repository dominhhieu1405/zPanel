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

Install_linuxsys()
{
	mkdir -p /www/server/panel/plugin/linuxsys
	echo '正在安装脚本文件...' > $install_tmp
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
		wget -O /www/server/panel/plugin/linuxsys/linuxsys_main.py $download_Url/install/plugin/linuxsys/linuxsys_main.py -T 5
		wget -O /www/server/panel/plugin/linuxsys/index.html $download_Url/install/plugin/linuxsys/index.html -T 5
		wget -O /www/server/panel/plugin/linuxsys/info.json $download_Url/install/plugin/linuxsys/info.json -T 5
		wget -O /www/server/panel/plugin/linuxsys/icon.png $download_Url/install/plugin/linuxsys/icon.png -T 5
	else
		wget -O /www/server/panel/plugin/linuxsys/linuxsys_main.py $download_Url/install/plugin/linuxsys_en/linuxsys_main.py -T 5
		wget -O /www/server/panel/plugin/linuxsys/index.html $download_Url/install/plugin/linuxsys_en/index.html -T 5
		wget -O /www/server/panel/plugin/linuxsys/info.json $download_Url/install/plugin/linuxsys_en/info.json -T 5
		wget -O /www/server/panel/plugin/linuxsys/icon.png $download_Url/install/plugin/linuxsys_en/icon.png -T 5
	fi
	echo '安装完成' > $install_tmp
}

Uninstall_linuxsys()
{
	rm -rf /www/server/panel/plugin/linuxsys
}


action=$1
if [ "${1}" == 'install' ];then
	Install_linuxsys
else
	Uninstall_linuxsys
fi
