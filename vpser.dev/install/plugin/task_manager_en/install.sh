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

pluginPath=/www/server/panel/plugin/task_manager

Install_task_manager()
{
	mkdir -p $pluginPath
	echo 'Installing script file...' > $install_tmp
	wget -O $pluginPath/task_manager.zip $download_Url/install/plugin/task_manager_en/task_manager.zip -T 5
	cd $pluginPath && unzip -o task_manager.zip
	wget -O $pluginPath/index.html $download_Url/install/plugin/task_manager_en/index.html -T 5
	wget -O $pluginPath/info.json $download_Url/install/plugin/task_manager_en/info.json -T 5
	wget -O $pluginPath/icon.png $download_Url/install/plugin/task_manager_en/icon.png -T 5
	echo > $pluginPath/task_manager_main.py
	echo > /www/server/panel/data/reload.pl
	echo 'The installation is complete' > $install_tmp
	echo 'Successify'
}

Uninstall_task_manager()
{
	rm -rf /www/server/panel/plugin/task_manager
	echo 'Successify'
}

action=$1
if [ "${1}" == 'install' ];then
	Install_task_manager
else
	Uninstall_task_manager
fi