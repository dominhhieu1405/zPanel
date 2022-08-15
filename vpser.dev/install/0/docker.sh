#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
install_tmp='/tmp/bt_install.pl'
grep "English" /www/server/panel/config/config.json
if [ "$?" -ne 0 ];then
	public_file=/www/server/panel/install/public.sh
	if [ ! -f $public_file ];then
	  wget -O $public_file http://vpser.dev/install/public.sh -T 5;
	fi
	. $public_file
	download_Url=$NODE_URL
else
	download_Url="https://node.aapanel.com"
fi
echo $download_Url

if [ ! -f "/etc/redhat-release" ];then
  systemver=`cat /etc/issue | grep -Ev '^$' | awk '{print $1}'`
else
  systemver=`cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/'`
fi
echo $systemver

redhat_version_file="/etc/redhat-release"
os_version=$(cat $redhat_version_file|grep CentOS|grep -Eo '([0-9]+\.)+[0-9]+'|grep -Eo '^[0-9]')

Install_Ubuntu_ce() {
    apt remove docker.io -y
    apt install docker.io -y
    apt install apt-transport-https ca-certificates curl software-properties-common -y
    echo 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable' >/etc/apt/sources.list.d/docker.list
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    apt install docker-ce -y
    update-rc.d docker defaults
    systemctl stop getty@tty1.service
    systemctl mask getty@tty1.service
    systemctl enable docker
    systemctl restart docker
}

Install_Debian_ce() {
    apt-get remove docker docker-engine docker.io containerd runc -y
    apt-get purge docker-ce docker-ce-cli containerd.io -y
    apt-get update -y
    apt-get install apt-transport-https ca-certificates curl gnupg lsb-release -y
    if [ -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
        \mv /usr/share/keyrings/docker-archive-keyring.gpg /usr/share/keyrings/docker-archive-keyring.gpg.$(date +%s).bak
    fi
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
    apt-get update -y
    apt-get install docker-ce docker-ce-cli containerd.io -y
    apt-get install apt-transport-https ca-certificates curl software-properties-common -y
    update-rc.d docker defaults
    systemctl stop getty@tty1.service
    systemctl mask getty@tty1.service
    systemctl enable docker
    systemctl restart docker
}

Install_Docker_ce()
{
  yum remove docker docker-common docker-selinux docker-engine -y
  yum install yum-utils -y

  grep "English" /www/server/panel/config/config.json
  if [ "$?" -ne 0 ];then
    yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
  else
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  fi
#   yum-config-manager --enable docker-ce-edge
  yum install docker-ce docker-ce-cli containerd.io -y
#   if [ "${os_version}" = "7" ];then
#     yum install $download_Url/install/plugin/docker/containerd.io-1.2.13-3.1.el7.x86_64.rpm -y
#   else
#     yum install $download_Url/install/plugin/docker/containerd.io-1.4.3-3.1.el8.x86_64.rpm -y
#   fi
#   yum-config-manager --disable docker-ce-edge
  echo 'move docker data to /www/server/docker ...';
  if [ -f /usr/bin/systemctl ];then
    systemctl stop docker
  else
    service docker stop
  fi
  
  www_dockerData="/www/server/docker"
  var_dockerData="/var/lib/docker"
  if [ ! -d $www_dockerData ];then
    if [ -d $var_dockerData ];then
        mv $var_dockerData $www_dockerData
    else
        mkdir $www_dockerData
    fi
  else
    rm -rf $var_dockerData
  fi
  ln -s $www_dockerData $var_dockerData
  
#   sed -i "s#ExecStart=\/usr\/bin\/dockerd -H fd:\/\/ --containerd=\/run\/containerd\/containerd.sock#ExecStart=\/usr\/bin\/dockerd --containerd=\/run\/containerd\/containerd.sock#g" /usr/lib/systemd/system/docker.service
  
  btpip install pytz
  yum install device-mapper-persistent-data lvm2 -y
  yum install atomic-registries container-storage-setup containers-common -y
  yum install oci-register-machine oci-systemd-hook oci-umount python-pytoml subscription-manager-rhsm-certificates yajl -y
  btpip install docker
  #pull image of bt-panel
  #imageVersion='5.6.0'
  #docker pull registry.cn-hangzhou.aliyuncs.com/bt-panel/panel:$imageVersion
  #docker tag `docker images|grep bt-panel|awk '{print $3}'` bt-panel:$imageVersion
}


Install_docker()
{

    if [ ! -d /www/server/panel/plugin/docker ];then
    	mkdir -p /www/server/panel/plugin/docker
    		if [ grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release ];then
    			Install_Ubuntu_ce
    		elif [ grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release ];then
    			Install_Debian_ce
    		elif [ -f "/usr/bin/yum" ];then
    			Install_Docker_ce
    	fi
    fi

  echo '正在安装脚本文件...' > $install_tmp
  grep "English" /www/server/panel/config/config.json
  if [ "$?" -ne 0 ];then
    wget -O /www/server/panel/plugin/docker/docker_main.py $download_Url/install/plugin/docker/docker_main.py -T 5
    wget -O /www/server/panel/plugin/docker/index.html $download_Url/install/plugin/docker/index.html -T 5
    wget -O /www/server/panel/plugin/docker/info.json $download_Url/install/plugin/docker/info.json -T 5
    wget -O /www/server/panel/plugin/docker/icon.png $download_Url/install/plugin/docker/icon.png -T 5
    wget -O /www/server/panel/plugin/docker/login-docker.html $download_Url/install/plugin/docker/login-docker.html -T 5
    wget -O /www/server/panel/plugin/docker/userdocker.html $download_Url/install/plugin/docker/userdocker.html -T 5
  else
    wget -O /www/server/panel/plugin/docker/docker_main.py $download_Url/install/plugin/docker_en/docker_main.py -T 5
    wget -O /www/server/panel/plugin/docker/index.html $download_Url/install/plugin/docker_en/index.html -T 5
    wget -O /www/server/panel/plugin/docker/info.json $download_Url/install/plugin/docker_en/info.json -T 5
    wget -O /www/server/panel/plugin/docker/icon.png $download_Url/install/plugin/docker_en/icon.png -T 5
    wget -O /www/server/panel/plugin/docker/login-docker.html $download_Url/install/plugin/docker_en/login-docker.html -T 5
    wget -O /www/server/panel/plugin/docker/userdocker.html $download_Url/install/plugin/docker_en/userdocker.html -T 5
  fi

  # install python module
  if [ -f /usr/bin/btpip ];then
    btpip install pytz
    btpip install docker
  else
    pip install pytz
    pip install docker
  fi
  
  #systemctl or service
  if [ -f /usr/bin/systemctl ];then
    pkill docker
    systemctl stop getty@tty1.service
    systemctl mask getty@tty1.service
    systemctl enable docker
    systemctl stop docker
    systemctl start docker
  else
    chkconfig --add docker
    chkconfig --level 2345 docker on
    service docker start
  fi

  echo '安装完成' > $install_tmp
}


upload_docker()
{

  echo '正在安装脚本文件...' > $install_tmp
  grep "English" /www/server/panel/config/config.json
  if [ "$?" -ne 0 ];then
    wget -O /www/server/panel/plugin/docker/docker_main.py $download_Url/install/plugin/docker/docker_main.py -T 5
    wget -O /www/server/panel/plugin/docker/index.html $download_Url/install/plugin/docker/index.html -T 5
    wget -O /www/server/panel/plugin/docker/info.json $download_Url/install/plugin/docker/info.json -T 5
    wget -O /www/server/panel/plugin/docker/icon.png $download_Url/install/plugin/docker/icon.png -T 5
    wget -O /www/server/panel/plugin/docker/login-docker.html $download_Url/install/plugin/docker/login-docker.html -T 5
    wget -O /www/server/panel/plugin/docker/userdocker.html $download_Url/install/plugin/docker/userdocker.html -T 5
  else
    wget -O /www/server/panel/plugin/docker/docker_main.py $download_Url/install/plugin/docker_en/docker_main.py -T 5
    wget -O /www/server/panel/plugin/docker/index.html $download_Url/install/plugin/docker_en/index.html -T 5
    wget -O /www/server/panel/plugin/docker/info.json $download_Url/install/plugin/docker_en/info.json -T 5
    wget -O /www/server/panel/plugin/docker/icon.png $download_Url/install/plugin/docker_en/icon.png -T 5
    wget -O /www/server/panel/plugin/docker/login-docker.html $download_Url/install/plugin/docker_en/login-docker.html -T 5
    wget -O /www/server/panel/plugin/docker/userdocker.html $download_Url/install/plugin/docker_en/userdocker.html -T 5
  fi
  echo '更新完成' > $install_tmp
}


Uninstall_docker()
{
  rm -rf /www/server/panel/plugin/docker
  rm -rf /var/lib/docker
  rm -rf /etc/yum.repos.d/docker-ce.repo
  if [ -f "/usr/bin/apt-get" ];then
    systemctl stop docker
    apt-get purge docker-ce docker-ce-cli containerd.io -y
  elif [ -f "/usr/bin/yum" ];then
    if [ -f /usr/bin/systemctl ];then
      systemctl disable docker
      systemctl stop docker
    else
      service docker stop
      chkconfig --level 2345 docker off
      chkconfig --del docker
    fi
    yum remove docker docker-common docker-selinux docker-engine docker-client -y
    yum remove docker-client-latest docker-latest docker-latest-logrotate docker-logrotate -y
  fi
  echo '卸载成功'
}


if [ "${1}" == 'install' ];then
  Install_docker
elif  [ "${1}" == 'update' ];then
  upload_docker
elif [ "${1}" == 'uninstall' ];then
  Uninstall_docker
fi
