#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

pluginPath=/www/server/panel/plugin/syssafe
python_bin='python'
if [ -f /www/server/panel/pyenv/bin/python ];then
    python_bin='/www/server/panel/pyenv/bin/python'
fi
public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
	wget -O $public_file http://en.zpanel.cc/install/public.sh --no-check-certificate -T 5;
fi
. $public_file
download_Url=$NODE_URL

Install_syssafe()
{
	mkdir -p $pluginPath

	cd $pluginPath
	echo > /www/server/panel/plugin/syssafe/syssafe_main.py
	wget -O /www/server/panel/plugin/syssafe/syssafe.zip $download_Url/install/plugin/syssafe_en/syssafe.zip --no-check-certificate -T 5
	unzip syssafe.zip
	rm -f syssafe.zip

	mkdir -p $pluginPath/sites
	initSh=/etc/init.d/bt_syssafe
	\cp -f $pluginPath/init.sh $initSh
	chmod +x $initSh
	if [ -f "/usr/bin/apt-get" ];then
		sudo update-rc.d bt_syssafe defaults
	else
		chkconfig --add bt_syssafe
		chkconfig --level 2345 bt_syssafe on
	fi
	$initSh stop
	$initSh start
	chmod -R 600 $pluginPath

	echo 'Successify'
}

Uninstall_syssafe()
{
	initSh=/etc/init.d/bt_syssafe
	$initSh stop
	chkconfig --del bt_syssafe
	$python_bin $pluginPath/bt_syssafe 0
	rm -rf $pluginPath
	rm -f $initSh
}


action=$1
if [ "${1}" == 'install' ];then
	Install_syssafe
else
	Uninstall_syssafe
fi
