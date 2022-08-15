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
Install_GDrive()
{
tmp=`python -V 2>&1|awk '{print $2}'`
pVersion=${tmp:0:3}
if [ -f "/usr/bin/btpip" ];then
  btpip install -I pyOpenSSL
  tmp=$(btpip list|grep google-api-python-client|awk '{print $2}')
  if [ $tmp != '1.7.11' ];then
    btpip uninstall google-api-python-client -y
    btpip install -I google-api-python-client==1.7.11 -i https://pypi.Python.org/simple
  fi
  tmp=$(btpip list|grep google-auth-httplib2|awk '{print $2}')
  if [ $tmp != '0.0.3' ];then
    btpip uninstall google-auth-httplib2 -y
    btpip install -I google-auth-httplib2==0.0.3 -i https://pypi.Python.org/simple
  fi
  tmp=$(btpip list|grep google-auth-oauthlib|awk '{print $2}')
  if [ $tmp != '0.4.1' ];then
    btpip uninstall google-auth-oauthlib -y
    btpip install -I google-auth-oauthlib==0.4.1 -i https://pypi.Python.org/simple
  fi
  tmp=$(btpip list|grep -E '^httplib2'|awk '{print $2}')
  if [ $tmp != '0.15.0' ];then
    btpip uninstall httplib2 -y
    btpip install -I httplib2==0.15.0 -i https://pypi.Python.org/simple
  fi
else
  pip install -I pyOpenSSL
  pip install -I google-api-python-client==1.7.11 google-auth-httplib2==0.0.3 google-auth-oauthlib==0.4.1 -i https://pypi.Python.org/simple
  pip install -I httplib2==0.15.0 -i https://pypi.Python.org/simple
fi
echo '正在安装脚本文件...' > $install_tmp
mkdir -p /www/server/panel/plugin/gdrive
grep "English" /www/server/panel/config/config.json
if [ "$?" -ne 0 ];then
	wget -O /www/server/panel/script/backup_gdrive.py $download_Url/install/plugin/gdrive/gdrive_main.py -T 5
	\cp -a -r /www/server/panel/script/backup_gdrive.py /www/server/panel/plugin/gdrive/gdrive_main.py
	wget -O /www/server/panel/plugin/gdrive/index.html $download_Url/install/plugin/gdrive/index.html -T 5
	wget -O /www/server/panel/plugin/gdrive/info.json $download_Url/install/plugin/gdrive/info.json -T 5
	wget -O /www/server/panel/plugin/gdrive/icon.png $download_Url/install/plugin/gdrive/icon.png -T 5
	wget -O /www/server/panel/plugin/gdrive/credentials.json $download_Url/install/plugin/gdrive/credentials.json -T 5
else
	wget -O /www/server/panel/script/backup_gdrive.py $download_Url/install/plugin/gdrive_en/gdrive_main.py -T 5
	\cp -a -r /www/server/panel/script/backup_gdrive.py /www/server/panel/plugin/gdrive/gdrive_main.py
	wget -O /www/server/panel/plugin/gdrive/index.html $download_Url/install/plugin/gdrive_en/index.html -T 5
	wget -O /www/server/panel/plugin/gdrive/info.json $download_Url/install/plugin/gdrive_en/info.json -T 5
	wget -O /www/server/panel/plugin/gdrive/icon.png $download_Url/install/plugin/gdrive_en/icon.png -T 5
	wget -O /www/server/panel/plugin/gdrive/credentials.json $download_Url/install/plugin/gdrive/credentials.json -T 5
fi
    ln -s /www/server/panel/plugin/gdrive/credentials.json /root/credentials.json

echo '安装完成' > $install_tmp
}

Uninstall_GDrive()
{
	rm -rf /www/server/panel/plugin/gdrive
	rm -f /www/server/panel/script/backup_gdrive.py
	echo '卸载完成' > $install_tmp
}


action=$1
if [ "${1}" == 'install' ];then
	Install_GDrive
	echo '1' > /www/server/panel/data/reload.pl
else
	Uninstall_GDrive
fi
