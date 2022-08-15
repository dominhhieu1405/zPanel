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
Install_Ftp()
{	
	btpip install PyMySQL==0.9.3
  btpip install paramiko==2.7.1
  pip install PyMySQL==0.9.3
  pip install paramiko==2.7.1
	mkdir -p /www/server/panel/plugin/ftp
	echo '正在安装脚本文件...' > $install_tmp
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
		wget -O /www/server/panel/plugin/ftp/ftp_main.py $download_Url/install/plugin/ftp/ftp_main.py -T 5
		wget -O /www/server/panel/plugin/ftp/index.html $download_Url/install/plugin/ftp/index.html -T 5
		wget -O /www/server/panel/plugin/ftp/info.json $download_Url/install/plugin/ftp/info.json -T 5
    rm -rf /www/server/panel/plugin/ftp/btftplib
    rm -rf /www/server/panel/plugin/ftp/btftplib.zip
	else
		wget -O /www/server/panel/script/backup_ftp.py $download_Url/install/plugin/ftp_en/ftp_main.py -T 5
		wget -O /www/server/panel/plugin/ftp/index.html $download_Url/install/plugin/ftp_en/index.html -T 5
		wget -O /www/server/panel/plugin/ftp/info.json $download_Url/install/plugin/ftp_en/info.json -T 5
		\cp -a -r /www/server/panel/script/backup_ftp.py /www/server/panel/plugin/ftp/ftp_main.py
	fi
	echo '安装完成' > $install_tmp
}

Uninstall_Ftp()
{
	rm -rf /www/server/panel/data/ftpAS.conf
	rm -rf /www/server/panel/data/ftpAs.conf
	rm -rf /www/server/panel/data/SSHFileTransferProtocolAS.conf
	rm -rf /www/server/panel/data/ftp_settingsAS.conf
	echo '卸载完成' > $install_tmp
}


action=$1
if [ "${1}" == 'install' ];then
	Install_Ftp
else
	Uninstall_Ftp
fi
