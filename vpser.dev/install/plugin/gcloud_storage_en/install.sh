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
Install_Gcloud()
{
	echo '正在安装前置组件...' > $install_tmp
#	if [ "${download_Url}" = "http://125.88.182.172:5880" ]; then
#		mkdir ~/.pip
#		cat > ~/.pip/pip.conf <<EOF
#[global]
#index-url = https://pypi.doubanio.com/simple/
#
#[install]
#trusted-host=pypi.doubanio.com
#EOF
#    fi
#	tmp=`python -V 2>&1|awk '{print $2}'`
#	pVersion=${tmp:0:3}
if [ -d "/www/server/panel/pyenv" ];then
	sudo btpip install ndg-httpsclient
	sudo btpip install --ignore-installed --upgrade google-cloud-storage
else
	sudo pip install ndg-httpsclient
	sudo pip install --ignore-installed --upgrade google-cloud-storage
fi

	echo '正在安装脚本文件...' > $install_tmp
	mkdir -p /www/server/panel/plugin/gcloud_storage
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
		wget -O /www/server/panel/script/backup_gcloud.py $download_Url/install/plugin/gcloud_storage/gcloud_storage_main.py -T 5
		\cp -a -r /www/server/panel/script/backup_gcloud.py /www/server/panel/plugin/gcloud_storage/gcloud_storage_main.py
		wget -O /www/server/panel/plugin/gcloud_storage/index.html $download_Url/install/plugin/gcloud_storage/index.html -T 5
		wget -O /www/server/panel/plugin/gcloud_storage/info.json $download_Url/install/plugin/gcloud_storage/info.json -T 5
		wget -O /www/server/panel/plugin/gcloud_storage/icon.png $download_Url/install/plugin/gcloud_storage/icon.png -T 5
	else
		wget -O /www/server/panel/script/backup_gcloud.py $download_Url/install/plugin/gcloud_storage_en/gcloud_storage_main.py -T 5
		\cp -a -r /www/server/panel/script/backup_gcloud.py /www/server/panel/plugin/gcloud_storage/gcloud_storage_main.py
		wget -O /www/server/panel/plugin/gcloud_storage/index.html $download_Url/install/plugin/gcloud_storage_en/index.html -T 5
		wget -O /www/server/panel/plugin/gcloud_storage/info.json $download_Url/install/plugin/gcloud_storage_en/info.json -T 5
		wget -O /www/server/panel/plugin/gcloud_storage/icon.png $download_Url/install/plugin/gcloud_storage_en/icon.png -T 5
	fi
	grep "GOOGLE_APPLICATION_CREDENTIALS" ~/.bash_profile
	if [ "$?" -ne 0 ];then
		echo 'export GOOGLE_APPLICATION_CREDENTIALS="/www/server/panel/plugin/gcloud_storage/google.json"' >> ~/.bash_profile
	fi
	echo > /www/server/panel/data/reload.pl
	echo '安装完成' > $install_tmp
}

Uninstall_Gcloud()
{
	rm -rf /www/server/panel/plugin/gcloud_storage
	rm -f /www/server/panel/script/backup_gcloud.py
	pip uninstall google-cloud-storage -y
	echo '卸载完成' > $install_tmp
}


action=$1
if [ "${1}" == 'install' ];then
	Install_Gcloud
else
	Uninstall_Gcloud
fi
