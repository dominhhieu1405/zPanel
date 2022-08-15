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
pluginPath=/www/server/panel/plugin/btapp

Install_btapp()
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
	mypip="/www/server/panel/pyenv/bin/pip"
	if [ -f $mypip ];then
		$mypip install pycryptodome
	else
		pip install pycryptodome
	fi
	mkdir -p $pluginPath
	echo $begin > $install_tmp
	wget -O $pluginPath/btapp_main.py $download_Url/install/plugin/btapp$en/btapp_main.py -T 5
	wget -O $pluginPath/index.html $download_Url/install/plugin/btapp$en/index.html -T 5
	wget -O $pluginPath/info.json $download_Url/install/plugin/btapp$en/info.json -T 5
	wget -O $pluginPath/icon.png $download_Url/install/plugin/btapp$en/icon.png -T 5
	wget -O $pluginPath/install.sh $download_Url/install/plugin/btapp$en/install.sh -T 5
	\cp -a -r /www/server/panel/plugin/btapp/icon.png /www/server/panel/BTPanel/static/img/soft_ico/ico-btapp.png
	echo $end > $install_tmp
}


Uninstall_btapp()
{
	rm -rf /www/server/panel/static/btapp
	rm -rf $pluginPath
}

if [ "${1}" == 'install' ];then
	Install_btapp
elif [ "${1}" == 'uninstall' ];then
	Uninstall_btapp
fi
