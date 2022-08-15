#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
	wget -O $public_file http://en.zpanel.cc/install/public.sh -T 5;
fi
. $public_file

download_Url=$NODE_URL
current=`date "+%Y-%m-%d %H:%M:%S"`
timeStamp=`date -d "$current" +%s`
currentTimeStamp=$((timeStamp*1000+`date "+%N"`/1000000))
Install_psync()
{
	pip install requests
	mkdir -p /www/server/panel/plugin/psync_api
	echo '正在安装脚本文件...' > $install_tmp
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
		wget -O /www/server/panel/plugin/psync_api/psync_api_main.py $download_Url/install/plugin/psync_api/psync_api_main.py -T 5
		wget -O /www/server/panel/plugin/psync_api/index.html $download_Url/install/plugin/psync_api/index.html -T 5
		wget -O /www/server/panel/plugin/psync_api/info.json $download_Url/install/plugin/psync_api/info.json -T 5
		wget -O /www/server/panel/plugin/psync_api/icon.png $download_Url/install/plugin/psync_api/icon.png -T 5
		wget -O /www/server/panel/plugin/psync_api/ico-success.png $download_Url/install/plugin/psync_api/ico-success.png -T 5
	else
		wget -O /www/server/panel/plugin/psync_api/psync_api_main.py $download_Url/install/plugin/psync_api_en/psync_api_main.py -T 5
		wget -O /www/server/panel/plugin/psync_api/index.html $download_Url/install/plugin/psync_api_en/index.html -T 5
		wget -O /www/server/panel/plugin/psync_api/info.json $download_Url/install/plugin/psync_api_en/info.json -T 5
		wget -O /www/server/panel/plugin/psync_api/icon.png $download_Url/install/plugin/psync_api_en/icon.png -T 5
		wget -O /www/server/panel/plugin/psync_api/ico-success.png $download_Url/install/plugin/psync_api_en/ico-success.png -T 5
	fi

unalias cp
cp -a -r /www/server/panel/plugin/psync_api/ico-success.png /www/server/panel/static/img/ico-success.png
cp -a -r /www/server/panel/plugin/psync_api/icon.png /www/server/panel/static/img/soft_ico/ico-psync_api.png
echo '安装完成' > $install_tmp
}

Uninstall_psync()
{
	rm -rf /www/server/panel/plugin/psync_api
}


action=$1
if [ "${1}" == 'install' ];then
	Install_psync
else
	Uninstall_psync
fi
