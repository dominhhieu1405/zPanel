#!/bin/bash
PATH=/www/server/panel/pyenv/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
download_Url=https://node.aapanel.com
pluginPath=/www/server/panel/plugin/ip_configuration

Install_ip_configuration()
{
    Pack="bridge-utils"
	if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ] ; then
		${PM} install ${Pack} -y
	elif [ "${PM}" == "apt-get" ]; then
		${PM} install ${Pack} -y
	fi
    mkdir -p $pluginPath
    wget -O $pluginPath/ip_configuration.zip $download_Url/install/plugin/ip_configuration_en/ip_configuration.zip -T 5 --no-check-certificate
    cd $pluginPath && unzip ip_configuration.zip
    echo 'Installing script files...' > $install_tmp
	echo 'installation is complete' > $install_tmp
	echo Success
}

Uninstall_ip_configuration()
{
rm -rf $pluginPath
}


action=$1
if [ "${1}" == 'install' ];then
	Install_ip_configuration
else
	Uninstall_ip_configuration
fi
