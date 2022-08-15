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
pluginPath=/www/server/panel/plugin/clear


Install_clear()
{
	mkdir -p $pluginPath
	echo 'Installing script file...' > $install_tmp
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
    wget -O $pluginPath/clear_main.py $download_Url/install/plugin/clear/clear_main.py -T 5
    wget -O $pluginPath/index.html $download_Url/install/plugin/clear/index.html -T 5
    wget -O $pluginPath/info.json $download_Url/install/plugin/clear/info.json -T 5
    wget -O $pluginPath/icon.png $download_Url/install/plugin/clear/icon.png -T 5
  else
    wget -O $pluginPath/clear_main.py $download_Url/install/plugin/clear_en/clear_main.py -T 5
    wget -O $pluginPath/index.html $download_Url/install/plugin/clear_en/index.html -T 5
    wget -O $pluginPath/info.json $download_Url/install/plugin/clear_en/info.json -T 5
    wget -O $pluginPath/icon.png $download_Url/install/plugin/clear_en/icon.png -T 5
  fi
	\cp -a -r /www/server/panel/plugin/clear/icon.png /www/server/panel/static/img/soft_ico/ico-clear.png
	echo '安装完成' > $install_tmp
}

Uninstall_clear()
{
	rm -rf $pluginPath
}

if [ "${1}" == 'install' ];then
	Install_clear
elif  [ "${1}" == 'update' ];then
	Install_clear
elif [ "${1}" == 'uninstall' ];then
	Uninstall_clear
fi
