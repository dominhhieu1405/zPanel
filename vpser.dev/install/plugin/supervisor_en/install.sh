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
pluginPath=/www/server/panel/plugin/supervisor

# 安装
Install_Supervisor()
{
    if [ -e '/www/server/panel/pyenv/' ]; then
        pipv='/www/server/panel/pyenv/bin/pip'
        path=/www/server/panel/pyenv/bin/supervisord
        py='/www/server/panel/pyenv/bin/python'
        echo_supervisord_conf='/www/server/panel/pyenv/bin/echo_supervisord_conf'
        supervisorctl='/www/server/panel/pyenv/bin/supervisorctl'
    else
        pipv='pip'
        py='python'
        path=supervisord
        echo_supervisord_conf='echo_supervisord_conf'
        supervisorctl='supervisorctl'
    fi
    
    $pipv install supervisor -i http://pypi.douban.com/simple --trusted-host pypi.douban.com --ignore-installed meld3

    mkdir -p /etc/supervisor
    $echo_supervisord_conf > /etc/supervisor/supervisord.conf

	mkdir -p $pluginPath
	mkdir -p $pluginPath/log
	mkdir -p $pluginPath/profile

	echo '正在安装脚本文件...' > $install_tmp
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
        wget -O $pluginPath/supervisor_main.py $download_Url/install/plugin/supervisor/supervisor_main.py -T 5
        wget -O $pluginPath/config.py $download_Url/install/plugin/supervisor/config.py -T 5
        wget -O $pluginPath/index.html $download_Url/install/plugin/supervisor/index.html -T 5
        wget -O $pluginPath/info.json $download_Url/install/plugin/supervisor/info.json -T 5
        wget -O $pluginPath/icon.png $download_Url/install/plugin/supervisor/icon.png -T 5
        wget -O $pluginPath/install.sh $download_Url/install/plugin/supervisor/install.sh -T 5
    else
        wget -O $pluginPath/supervisor_main.py $download_Url/install/plugin/supervisor_en/supervisor_main.py -T 5
        wget -O $pluginPath/config.py $download_Url/install/plugin/supervisor_en/config.py -T 5
        wget -O $pluginPath/index.html $download_Url/install/plugin/supervisor_en/index.html -T 5
        wget -O $pluginPath/info.json $download_Url/install/plugin/supervisor_en/info.json -T 5
        wget -O $pluginPath/icon.png $download_Url/install/plugin/supervisor_en/icon.png -T 5
        wget -O $pluginPath/install.sh $download_Url/install/plugin/supervisor/install.sh -T 5
    fi
	\cp -a -r $pluginPath/icon.png /www/server/panel/BTPanel/static/img/soft_ico/ico-supervisor.png

	# 防止系统加固误清理
	s_file=/www/server/panel/plugin/syssafe/config.json
	if [ -f $s_file ];then
	    is_exp=$(cat $s_file|grep supervisord)
	    if [ "$is_exp" = "" ];then
	        sed -i 's/"PM2"/"PM2","supervisord"/' $s_file
	        /etc/init.d/bt_syssafe restart
	    fi
	fi

    $py /www/server/panel/plugin/supervisor/config.py
    $path -c /etc/supervisor/supervisord.conf
    $supervisorctl reload


    if [ -e '/usr/lib/systemd/system/' ]; then
        service_path=/usr/lib/systemd/system/supervisord.service
    else
        service_path=/lib/systemd/system/supervisord.service
    fi
    touch $service_path
    echo "[Unit]
Description=Process Monitoring and Control Daemon
After=rc-local.service nss-user-lookup.target

[Service]
Type=forking
ExecStart=$path -c /etc/supervisor/supervisord.conf

[Install]
WantedBy=multi-user.target" > $service_path
    systemctl daemon-reload
    systemctl enable supervisord
    echo '安装完成' > $install_tmp
}

# 卸载
Uninstall_Supervisor()
{
  if [ -e '/www/server/panel/pyenv/' ]; then
      pipv='/www/server/panel/pyenv/bin/pip'
      path=/www/server/panel/pyenv/bin/supervisord
      py='/www/server/panel/pyenv/bin/python'
      echo_supervisord_conf='/www/server/panel/pyenv/bin/echo_supervisord_conf'
      supervisorctl='/www/server/panel/pyenv/bin/supervisorctl'
  else
      pipv='pip'
      py='python'
      path=/usr/bin/supervisord
      echo_supervisord_conf='echo_supervisord_conf'
      supervisorctl='supervisorctl'
  fi
	$supervisorctl stop all
	rm -rf $pluginPath
	rm -rf /etc/supervisor
	if [ -e '/usr/lib/systemd/system/' ]; then
        rm -f /usr/lib/systemd/system/supervisord.service
    else
        rm -f /lib/systemd/system/supervisord.service
    fi
	systemctl daemon-reload
  $pipv uninstall supervisor -y
}

if [ "${1}" == 'install' ];then
	Install_Supervisor
elif [ "${1}" == 'uninstall' ];then
	Uninstall_Supervisor
else
    echo 'Error'
fi