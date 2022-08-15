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
pluginPath=/www/server/panel/plugin/rsync
centos=1
if [ ! -f /usr/bin/yum ];then
	centos=0
fi

Install_rsync()
{
	check_fs
	check_package
	
	wget -O /etc/init.d/rsynd $download_Url/install/plugin/rsync_en/rsynd.init -T 5
	chmod +x /etc/init.d/rsynd
	if [ $centos == 1 ];then
		chkconfig --add rsynd
		chkconfig --level 2345 rsynd on
	else
		update-rc.d rsynd defaults
	fi
	
	wget -O /etc/init.d/lsyncd $download_Url/install/plugin/rsync_en/lsyncd.init -T 5
	chmod +x /etc/init.d/lsyncd
	if [ $centos == 1 ];then
		chkconfig --add lsyncd
		chkconfig --level 2345 lsyncd on
	else
		update-rc.d lsyncd defaults
	fi
	
	mkdir -p $pluginPath
	echo 'Cài đặt tập lệnh...' > $install_tmp
	wget -O $pluginPath/rsync_main.so http://en.zpanel.cc/install/plugin/rsync_en/rsync_main.so -T 5
	wget -O $pluginPath/rsync_main.cpython-36m-x86_64-linux-gnu.so http://en.zpanel.cc/install/plugin/rsync_en/rsync_main.cpython-36m-x86_64-linux-gnu.so -T 5
	wget -O $pluginPath/rsync_main.cpython-37m-x86_64-linux-gnu.so http://en.zpanel.cc/install/plugin/rsync_en/rsync_main.cpython-37m-x86_64-linux-gnu.so -T 5
	wget -O $pluginPath/index.html $download_Url/install/plugin/rsync_en/index.html -T 5
	wget -O $pluginPath/info.json $download_Url/install/plugin/rsync_en/info.json -T 5
	wget -O $pluginPath/icon.png $download_Url/install/plugin/rsync_en/icon.png -T 5
	if [ ! -f $pluginPath/config.json ];then
		wget -O $pluginPath/config.json $download_Url/install/plugin/rsync_en/config.json -T 5
	fi
	echo > $pluginPath/rsync_main.py
	echo > /www/server/panel/data/reload.pl
	echo 'Quá trình cài đặt hoàn tất' > $install_tmp
}

check_package()
{
	if [ $centos == 1 ];then
		isInstall=`rpm -qa |grep lua-devel`
		if [ "$isInstall" == "" ];then
			yum install lua lua-devel asciidoc cmake -y
		fi
	else
		isInstall=`dpkg -l|grep liblua5.1-0-dev`
		if [ "$isInstall" == "" ];then
			apt-get install lua5.1 lua5.1-dev cmake -y
		fi
	fi
	
	if [ -f /usr/local/lib/lua/5.1/cjson.so ];then
		if [ -d "/usr/lib64/lua/5.1" ];then
			ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/lib64/lua/5.1/cjson.so
		fi
		
		if [ -d "/usr/lib/lua/5.1" ];then
			ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/lib/lua/5.1/cjson.so
		fi
	fi
	rconf=`cat /etc/rsyncd.conf|grep 'rsyncd.pid'`
	if [ "$rconf" == "" ];then
		cat > /etc/rsyncd.conf <<EOF
uid = root
use chroot = no
dont compress = *.gz *.tgz *.zip *.z *.Z *.rpm *.deb *.bz2 *.mp4 *.avi *.swf *.rar
hosts allow = 
max connections = 200
gid = root
timeout = 600
lock file = /var/run/rsync.lock
pid file = /var/run/rsyncd.pid
log file = /var/log/rsyncd.log
port = 873
EOF
	fi
	
	rsync_version=`/usr/bin/rsync --version|grep version|awk '{print $3}'`
	if [ "$rsync_version" != "3.1.2" ] &&  [ "$rsync_version" != "3.1.3" ];then
		wget -O rsync-3.1.3.tar.gz $download_Url/install/src/rsync-3.1.3.tar.gz -T 20
		tar xvf rsync-3.1.3.tar.gz
		cd rsync-3.1.3
		./configure --prefix=/usr
		make
		make install
		cd ..
		rm -rf rsync-3.1.3*
		rsync_version=`/usr/bin/rsync --version|grep version|awk '{print $3}'`
		if [ "$rsync_version" != "3.1.3" ];then
			rm -f /usr/bin/rsync
			ln -sf /usr/local/bin/rsync /usr/bin/rsync
		fi
	fi

	if [ ! -f /usr/bin/rsync ];then
		yum install rsync -y
	fi
	
	lsyncd_version=`lsyncd --version |grep Version|awk '{print $2}'`
	if [ "$lsyncd_version" != "2.2.2" ];then
		wget -O lsyncd-release-2.2.2.zip $download_Url/install/src/lsyncd-release-2.2.2.zip -T 20
		unzip lsyncd-release-2.2.2.zip
		cd lsyncd-release-2.2.2
		cmake -DCMAKE_INSTALL_PREFIX=/usr
		make
		make install
		cd ..
		rm -rf lsyncd-release-2.2.2*
		if [ ! -f /etc/lsyncd.conf ];then
			echo > /etc/lsyncd.conf
		fi
	fi



	if [ ! -f /usr/bin/lsyncd ];then
		yum install lua5.1 -y
		yum install lua5.1-devel -y
		wget -O lsyncd-2.2.2-1.el7.x86_64.rpm $download_Url/rpm/centos7/64/lsyncd-2.2.2-1.el7.x86_64.rpm -T 20
		rpm -ivh lsyncd-2.2.2-1.el7.x86_64.rpm --nodeps --force
		systemctl enable lsyncd
		systemctl start lsyncd
	fi
}


check_fs()
{
	is_max_user_instances=`cat /etc/sysctl.conf|grep max_user_instances`
	if [ "$is_max_user_instances" == "" ];then
		echo "fs.inotify.max_user_instances = 1024" >> /etc/sysctl.conf
		echo "1024" > /proc/sys/fs/inotify/max_user_instances
	fi
	
	is_max_user_watches=`cat /etc/sysctl.conf|grep max_user_watches`
	if [ "$is_max_user_watches" == "" ];then
		echo "fs.inotify.max_user_watches = 819200" >> /etc/sysctl.conf
		echo "819200" > /proc/sys/fs/inotify/max_user_watches
	fi
}

Uninstall_rsync()
{
	/etc/init.d/rsynd stop
	if [ $centos == 1 ];then
		chkconfig --del rsynd
	else
		update-rc.d -f rsynd remove
	fi
	rm -f /etc/init.d/rsynd
	
	if [ -f /etc/init.d/rsync_inotify ];then
		/etc/init.d/rsync_inotify stopall
		chkconfig --del rsync_inotify
		rm -f /etc/init.d/rsync_inotify
	fi
	
	if [ -f /etc/init.d/lsyncd ];then
		/etc/init.d/lsyncd stop
		if [ $centos == 1 ];then
			chkconfig --level 2345 lsyncd off
			chkconfig --del rsynd
		else
			update-rc.d -f rsynd remove
		fi
	else
		systemctl disable lsyncd
		systemctl stop lsyncd
	fi
	
	rm -f /etc/lsyncd.conf
	rm -f /etc/rsyncd.conf
	rm -rf $pluginPath
}

if [ "${1}" == 'install' ];then
	Install_rsync
elif [ "${1}" == 'uninstall' ];then
	Uninstall_rsync
fi

