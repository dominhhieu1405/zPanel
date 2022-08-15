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
pluginPath=/www/server/panel/plugin/tomcat2

Install_tomcat2()
{
	mkdir -p $pluginPath
	echo '正在安装脚本文件...' > $install_tmp
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
		wget -O $pluginPath/tomcat2_main.py $download_Url/install/plugin/tomcat2/tomcat2_main.py -T 5
		wget -O $pluginPath/index.html $download_Url/install/plugin/tomcat2/index.html -T 5
		wget -O $pluginPath/info.json $download_Url/install/plugin/tomcat2/info.json -T 5
		wget -O $pluginPath/icon.png $download_Url/install/plugin/tomcat2/icon.png -T 5
	else
		wget -O $pluginPath/tomcat2_main.py $download_Url/install/plugin/tomcat2_en/tomcat2_main.py -T 5
		wget -O $pluginPath/index.html $download_Url/install/plugin/tomcat2_en/index.html -T 5
		wget -O $pluginPath/info.json $download_Url/install/plugin/tomcat2_en/info.json -T 5
		wget -O $pluginPath/icon.png $download_Url/install/plugin/tomcat2_en/icon.png -T 5
	fi
	\cp -a -r /www/server/panel/plugin/tomcat2/icon.png /www/server/panel/static/img/soft_ico/ico-tomcat2.png
	echo '安装完成' > $install_tmp
}

Uninstall_tomcat2()
{
	rm -rf $pluginPath
}

if [ "${1}" == 'install' ];then
	Install_tomcat2
elif  [ "${1}" == 'update' ];then
	Install_tomcat2
elif [ "${1}" == 'uninstall' ];then
	Uninstall_tomcat2
fi
