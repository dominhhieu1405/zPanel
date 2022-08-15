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
pluginPath=/www/server/panel/plugin/tamper_proof
pyVersion=$(python -c 'import sys;print(sys.version_info[0]);')
py_zi=$(python -c 'import sys;print(sys.version_info[1]);')

Install_tamper_proof()
{
	mkdir -p $pluginPath
	mkdir -p $pluginPath/sites
	echo 'Installing script file...' > $install_tmp
	if [  -f /www/server/panel/pyenv/bin/python ];then
	  /www/server/panel/pyenv/bin/pip install pyinotify
		wget -O $pluginPath/tamper_proof_main.so $download_Url/install/plugin/tamper_proof_en/tamper_proof_main.cpython-37m-x86_64-linux-gnu.so -T 5
	else
	  	pip install pyinotify
		if [ "$pyVersion" == 2 ];then
        	wget -O $pluginPath/tamper_proof_main.so $download_Url/install/plugin/tamper_proof_en/tamper_proof_main.so -T 5
		else
			if [ "$py_zi" == 6 ];then
        		wget -O $pluginPath/tamper_proof_main.so $download_Url/install/plugin/tamper_proof_en/tamper_proof_main.cpython-36m-x86_64-linux-gnu.so -T 5
			fi
			if [ "$py_zi" == 7 ];then
		    	wget -O $pluginPath/tamper_proof_main.so $download_Url/install/plugin/tamper_proof_en/tamper_proof_main.cpython-37m-x86_64-linux-gnu.so -T 5
			fi
		fi
	fi
	wget -O $pluginPath/tamper_proof_main.py $download_Url/install/plugin/tamper_proof_en/tamper_proof_main.py -T 5
	wget -O $pluginPath/tamper_proof_service.py $download_Url/install/plugin/tamper_proof_en/tamper_proof_service.py -T 5
	wget -O $pluginPath/index.html $download_Url/install/plugin/tamper_proof_en/index.html -T 5
	wget -O $pluginPath/config.json $download_Url/install/plugin/tamper_proof_en/config.json -T 5
	wget -O $pluginPath/icon.png $download_Url/install/plugin/tamper_proof_en/icon.png -T 5
	wget -O $pluginPath/info.json $download_Url/install/plugin/tamper_proof_en/info.json -T 5

	siteJson=$pluginPath/sites.json
	if [ ! -f $siteJson ];then
		wget -O $siteJson $download_Url/install/plugin/tamper_proof_en/sites.json -T 5
	fi
	initSh=/etc/init.d/bt_tamper_proof
	wget -O $initSh $download_Url/install/plugin/tamper_proof_en/init.sh -T 5
	chmod +x /etc/init.d/bt_tamper_proof
	update-rc.d bt_tamper_proof defaults
	chkconfig --add bt_tamper_proof
	chkconfig --level 2345 bt_tamper_proof on
	check_fs
	chown -R root.root $pluginPath
    chmod -R 600 $pluginPath
	$initSh stop
	$initSh start
	rm -rf $pluginPath/sites
	echo '安装完成' > $install_tmp
}

check_fs()
{
	is_max_user_instances=`cat /etc/sysctl.conf|grep max_user_instances`
	if [ "$is_max_user_instances" == "" ];then
		echo "fs.inotify.max_user_instances = 1024" >> /etc/sysctl.conf
		echo "1024" > /proc/sys/fs/inotify/max_user_instances
	fi
	
	is_max_user_watches=`cat /etc/sysctl.conf|grep max_user_watches`
	if [ "$is_max_user_watches" == "" ];then
		echo "fs.inotify.max_user_watches = 81920000" >> /etc/sysctl.conf
		echo "81920000" > /proc/sys/fs/inotify/max_user_watches
	fi
}

Uninstall_tamper_proof()
{
	initSh=/etc/init.d/bt_tamper_proof
	$initSh stop
	update-rc.d bt_tamper_proof remove
	chkconfig --del bt_tamper_proof
	rm -rf $pluginPath
	rm -f $initSh
}


action=$1
if [ "${1}" == 'install' ];then
	Install_tamper_proof
	echo > /www/server/panel/data/reload.pl

else
	Uninstall_tamper_proof
fi
