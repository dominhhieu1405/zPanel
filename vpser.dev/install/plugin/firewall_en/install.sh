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
echo $download_Url
pluginPath=/www/server/panel/plugin/firewall

Get_System_Name()
{
    if grep -Eqii "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        yum install -y ipset
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        yum install -y ipset
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        apt install -y ipset 
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        apt install -y ipset 
    fi
}

# 安装
Install_Firewall()
{
	mkdir -p $pluginPath
    
	echo 'Installing script file...' > $install_tmp
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
		wget -O $pluginPath/firewall_main.py $download_Url/install/plugin/firewall/firewall_main.py -T 5
		wget -O $pluginPath/trigger.py $download_Url/install/plugin/firewall/trigger.py -T 5
		wget -O $pluginPath/index.html $download_Url/install/plugin/firewall/index.html -T 5
		wget -O $pluginPath/info.json $download_Url/install/plugin/firewall/info.json -T 5
		wget -O $pluginPath/country.txt $download_Url/install/plugin/firewall/country.txt -T 5
		wget -O $pluginPath/ips.txt $download_Url/install/plugin/firewall/ips.txt -T 5
		wget -O $pluginPath/whitelist.txt $download_Url/install/plugin/firewall/whitelist.txt -T 5
		wget -O $pluginPath/icon.png $download_Url/install/plugin/firewall/icon.png -T 5
	else
		wget -O $pluginPath/firewall_main.py $download_Url/install/plugin/firewall_en/firewall_main.py -T 5
		wget -O $pluginPath/trigger.py $download_Url/install/plugin/firewall_en/trigger.py -T 5
		wget -O $pluginPath/index.html $download_Url/install/plugin/firewall_en/index.html -T 5
		wget -O $pluginPath/info.json $download_Url/install/plugin/firewall_en/info.json -T 5
		wget -O $pluginPath/country.txt $download_Url/install/plugin/firewall_en/country.txt -T 5
		wget -O $pluginPath/ips.txt $download_Url/install/plugin/firewall/ips.txt -T 5
		wget -O $pluginPath/icon.png $download_Url/install/plugin/firewall_en/icon.png -T 5
	fi
	\cp -a -r $pluginPath/icon.png /www/server/panel/BTPanel/static/img/soft_ico/ico-firewall.png
  python /www/server/panel/plugin/firewall/trigger.py
  Get_System_Name
  if hash btpip 2>/dev/null; then
    btpip install ipy
  else
    pip install ipy
  fi
  echo 'The installation is complete' > $install_tmp
}

# 卸载
Uninstall_Firewall()
{
	rm -rf $pluginPath
}

Update_Firewall()
{
  echo 'Installing script file...' > $install_tmp
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
		wget -O $pluginPath/firewall_main.py $download_Url/install/plugin/firewall/firewall_main.py -T 5
		wget -O $pluginPath/trigger.py $download_Url/install/plugin/firewall/trigger.py -T 5
		wget -O $pluginPath/index.html $download_Url/install/plugin/firewall/index.html -T 5
		wget -O $pluginPath/info.json $download_Url/install/plugin/firewall/info.json -T 5
		wget -O $pluginPath/country.txt $download_Url/install/plugin/firewall/country.txt -T 5
		wget -O $pluginPath/ips.txt $download_Url/install/plugin/firewall/ips.txt -T 5
		wget -O $pluginPath/whitelist.txt $download_Url/install/plugin/firewall/whitelist.txt -T 5
		wget -O $pluginPath/icon.png $download_Url/install/plugin/firewall/icon.png -T 5
	else
		wget -O $pluginPath/firewall_main.py $download_Url/install/plugin/firewall_en/firewall_main.py -T 5
		wget -O $pluginPath/trigger.py $download_Url/install/plugin/firewall_en/trigger.py -T 5
		wget -O $pluginPath/index.html $download_Url/install/plugin/firewall_en/index.html -T 5
		wget -O $pluginPath/info.json $download_Url/install/plugin/firewall_en/info.json -T 5
		wget -O $pluginPath/country.txt $download_Url/install/plugin/firewall_en/country.txt -T 5
		wget -O $pluginPath/ips.txt $download_Url/install/plugin/firewall/ips.txt -T 5
		wget -O $pluginPath/icon.png $download_Url/install/plugin/firewall_en/icon.png -T 5
	fi
	\cp -a -r $pluginPath/icon.png /www/server/panel/BTPanel/static/img/soft_ico/ico-firewall.png
  if hash btpip 2>/dev/null; then
    btpip install ipy
  else
    pip install ipy
  fi
  echo 'The installation is complete' > $install_tmp
}

if [ "${1}" == 'install' ];then
	Install_Firewall
elif [ "${1}" == 'update' ];then
	Update_Firewall
else
    Uninstall_Firewall
fi
