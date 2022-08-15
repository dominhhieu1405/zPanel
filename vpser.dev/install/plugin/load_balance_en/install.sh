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
echo 'download url...'
echo $download_Url

pluginPath=/www/server/panel/plugin/load_balance
cloudpath=$download_Url/install/plugin/load_balance_en

cpu_arch=`arch`

Install_load_balance()
{
  if [[ $cpu_arch != "x86_64" ]];then
    echo 'Currently does not support the installation of non-x86 architecture systems'
    exit 0
  fi
  mkdir -p $pluginPath/tcp_config
  mkdir -p /www/wwwlogs/load_balancing
  chown -R www:www /www/wwwlogs/load_balancing

  echo 'Installing script file...' > $install_tmp
  echo > $pluginPath/load_balance_main.py
  wget -O $pluginPath/load_balance_main.so $cloudpath/load_balance_main.so -T 5
  wget -O $pluginPath/load_balance_main.cpython-36m-x86_64-linux-gnu.so $cloudpath/load_balance_main.cpython-36m-x86_64-linux-gnu.so -T 5
  wget -O $pluginPath/load_balance_main.cpython-37m-x86_64-linux-gnu.so $cloudpath/load_balance_main.cpython-37m-x86_64-linux-gnu.so -T 5
  wget -O /www/server/panel/plugin/load_balance/check_task.py $cloudpath/check_task.py -T 5
  wget -O /www/server/panel/plugin/load_balance/index.html $cloudpath/index.html -T 5
  wget -O /www/server/panel/plugin/load_balance/info.json $cloudpath/info.json -T 5
  wget -O /www/server/panel/plugin/load_balance/icon.png $cloudpath/icon.png -T 5
  wget -O /www/server/panel/vhost/nginx/load_total.lua $cloudpath/load_total.lua -T 5

  \cp -a -r /www/server/panel/plugin/load_balance/icon.png /www/server/panel/BTPanel/static/img/soft_ico/ico-load_balance.png


  echo "lua_shared_dict load_total 64m;" > /www/server/panel/vhost/nginx/load_balance_shared.conf
  echo 'The installation is complete' > $install_tmp
}

Uninstall_load_balance()
{
  rm -rf /www/server/panel/plugin/load_balance
  rm -f /www/server/panel/vhost/nginx/load_balance_shared.conf
  rm -f /www/server/panel/vhost/nginx/load_total.lua
}

action=$1
if [ "${1}" == 'install' ];then
  Install_load_balance
else
  Uninstall_load_balance
fi
