#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
install_tmp='/tmp/bt_install.pl'
public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
	wget -O $public_file http://en.zpanel.cc/install/public.sh -T 5;
fi
. $public_file
if [ -d "/www/server/panel/pyenv" ];then
  btpip install boto3
else
  pip install boto3
fi
download_Url=$NODE_URL
Install_AWS()
{
	mkdir -p /www/server/panel/plugin/aws_s3
	echo 'Installing script file...' > $install_tmp
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
		wget -O /www/server/panel/plugin/aws_s3/aws_s3.zip $download_Url/install/plugin/aws_s3/aws_s3.zip -T 5
	else
		wget -O /www/server/panel/plugin/aws_s3/aws_s3.zip $download_Url/install/plugin/aws_s3_en/aws_s3.zip -T 5
	fi
	cd /www/server/panel/plugin/aws_s3
	unzip -o aws_s3.zip
	rm aws_s3.zip
	echo 'The installation is complete' > $install_tmp
}

Uninstall_AWS()
{
	rm -rf /www/server/panel/plugin/aws_s3
	echo 'Uninstall complete' > $install_tmp
}


action=$1
if [ "${1}" == 'install' ];then
	Install_AWS
else
	Uninstall_AWS
fi
