#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
os_bit=$(getconf LONG_BIT)
is_arm=$(uname -a|grep -E 'aarch64|arm|ARM')

if [ "$os_bit" = "32" ] || [ "$is_arm" != "" ];then
	echo "========================================="
	grep "English" /www/server/panel/config/config.json > /dev/null
	if [ "$?" -ne 0 ];then
	  echo "错误: 不支持32位和ARM/AARCH64平台的系统!"
	else
	  echo "Error: 32-bit and ARM/AARCH64 platform systems are not supported!"
	fi
	echo "========================================="
	exit 0;
fi

install_tmp='/tmp/bt_install.pl'
public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
	wget -O $public_file http://en.zpanel.cc/install/public.sh -T 5;
fi
. $public_file

download_Url=$NODE_URL
pluginPath=/www/server/panel/plugin/site_speed
extFile=""
version=""


Install_site_speed()
{
  grep "English" /www/server/panel/config/config.json > /dev/null
	if [ "$?" -ne 0 ];then
	  Install_site_speed_cn
	else
	  Install_site_speed_en
	fi
}

Install_site_speed_en()
{
	sp_path=/www/server/speed
	mkdir -p $sp_path/total
	mkdir -p $pluginPath

	if [ ! -f /usr/bin/nc ];then
		if [ -f /usr/bin/apt ];then
			apt install ncat -y
		else
			yum install nc -y
		fi
	fi

	Install_cjson
	Install_socket
	Install_mod_lua
	Install_gzip_mod

	echo 'Installing script file...' > $install_tmp
	wget -O $pluginPath/site_speed_main.so $download_Url/install/plugin/site_speed_en/site_speed_main.so -T 5
	wget -O $pluginPath/site_speed_main.cpython-36m-x86_64-linux-gnu.so $download_Url/install/plugin/site_speed_en/site_speed_main.cpython-36m-x86_64-linux-gnu.so -T 5
	wget -O $pluginPath/site_speed_main.cpython-37m-x86_64-linux-gnu.so $download_Url/install/plugin/site_speed_en/site_speed_main.cpython-37m-x86_64-linux-gnu.so -T 5



	echo > $pluginPath/site_speed_main.py
	wget -O $pluginPath/index.html $download_Url/install/plugin/site_speed_en/index.html -T 5
	wget -O $pluginPath/info.json $download_Url/install/plugin/site_speed_en/info.json -T 5

	if [ ! -f $pluginPath/config.json ];then
		wget -O $pluginPath/config.json $download_Url/install/plugin/site_speed_en/config.json -T 5
	fi

	if [ ! -f $pluginPath/sites.json ];then
		wget -O $pluginPath/sites.json $download_Url/install/plugin/site_speed_en/sites.json -T 5
	fi

	if [ ! -f $pluginPath/rules.json ];then
		wget -O $pluginPath/rules.json $download_Url/install/plugin/site_speed_en/rules.json -T 5
	fi

	wget -O $pluginPath/icon.png $download_Url/install/plugin/site_speed_en/icon.png -T 5

	speed_conf_file=/www/server/panel/vhost/nginx/speed.conf
	m=$(cat $speed_conf_file|grep lua_shared_dict)
	if [ "$m" == "" ];then
		m="lua_shared_dict site_cache 64m;"
	fi
	wget -O  $speed_conf_file $download_Url/install/plugin/site_speed/speed.conf -T 5
	sed -i "s/^lua_shared_dict.*/$m/" $speed_conf_file

	waf_file=/www/server/panel/vhost/apache/btwaf.conf
	if [ ! -f $waf_file ];then
		echo "LoadModule lua_module modules/mod_lua.so" > $waf_file
	fi
	chattr +i $waf_file
	mkdir -p /www/server/panel/plugin/btwaf_httpd
	wget -O $sp_path/cookie.lua $download_Url/install/plugin/site_speed/speed/cookie.lua -T 5
	wget -O $sp_path/ffi-zlib.lua $download_Url/install/plugin/site_speed/speed/ffi-zlib.lua -T 5
	wget -O $sp_path/speed.lua $download_Url/install/plugin/site_speed/speed/speed.lua -T 5
	wget -O $sp_path/nginx_get.lua $download_Url/install/plugin/site_speed/speed/nginx_get.lua -T 5
	wget -O $sp_path/nginx_set.lua $download_Url/install/plugin/site_speed/speed/nginx_set.lua -T 5
	wget -O $sp_path/httpd_speed.lua $download_Url/install/plugin/site_speed/speed/httpd_speed.lua -T 5
	wget -O $sp_path/memcached.lua $download_Url/install/plugin/site_speed/speed/memcached.lua -T 5
	wget -O $sp_path/CRC32.lua $download_Url/install/plugin/site_speed/speed/CRC32.lua -T 5
	speed_conf_file=/www/server/panel/vhost/apache/speed.conf
	wget -O  $speed_conf_file $download_Url/install/plugin/site_speed/speed_httpd.conf -T 5
	if [ ! -f $sp_path/config.lua ];then
		wget -O $sp_path/config.lua $download_Url/install/plugin/site_speed/speed/config.lua -T 5
	fi

	ng_waf_file=/www/server/panel/vhost/nginx/btwaf.conf
	if [ -f $ng_waf_file ];then
		sed -i "s/^body_filter_by_lua_file/#body_filter_by_lua_file/" $ng_waf_file
	fi

	site_cache_path=/www/server/panel/plugin/site_cache
	if [ -f $site_cache/info.json ];then
		wget -O $site_cache/install.sh $download_Url/install/plugin/site_cache/install.sh -T 5
		bash $site_cache/install.sh uninstall
	fi

	chown -R www:www $sp_path
	chmod -R 755 $sp_path

	if [ -f /etc/init.d/nginx ];then
		/etc/init.d/nginx reload
	else
		/etc/init.d/httpd reload
	fi
	echo > /www/server/panel/data/reload.pl
	echo 'The installation is complete' > $install_tmp
}


Install_site_speed_cn()
{
	sp_path=/www/server/speed
	mkdir -p $sp_path/total
	mkdir -p $pluginPath
	if [ ! -f /usr/bin/nc ];then
		if [ -f /usr/bin/apt ];then
			apt install ncat -y
		else
			yum install nc -y
		fi
	fi
	Install_cjson
	Install_socket
	Install_mod_lua
	Install_gzip_mod

	echo 'Installing script file...' > $install_tmp
	wget -O $pluginPath/site_speed_main.so $download_Url/install/plugin/site_speed/site_speed_main.so -T 5
	wget -O $pluginPath/site_speed_main.cpython-36m-x86_64-linux-gnu.so $download_Url/install/plugin/site_speed/site_speed_main.cpython-36m-x86_64-linux-gnu.so -T 5
	wget -O $pluginPath/site_speed_main.cpython-37m-x86_64-linux-gnu.so $download_Url/install/plugin/site_speed/site_speed_main.cpython-37m-x86_64-linux-gnu.so -T 5



	echo > $pluginPath/site_speed_main.py
	wget -O $pluginPath/index.html $download_Url/install/plugin/site_speed/index.html -T 5
	wget -O $pluginPath/info.json $download_Url/install/plugin/site_speed/info.json -T 5

	if [ ! -f $pluginPath/config.json ];then
		wget -O $pluginPath/config.json $download_Url/install/plugin/site_speed/config.json -T 5
	fi

	if [ ! -f $pluginPath/sites.json ];then
		wget -O $pluginPath/sites.json $download_Url/install/plugin/site_speed/sites.json -T 5
	fi

	if [ ! -f $pluginPath/rules.json ];then
		wget -O $pluginPath/rules.json $download_Url/install/plugin/site_speed/rules.json -T 5
	fi

	wget -O $pluginPath/icon.png $download_Url/install/plugin/site_speed/icon.png -T 5

	speed_conf_file=/www/server/panel/vhost/nginx/speed.conf
	m=$(cat $speed_conf_file|grep lua_shared_dict)
	if [ "$m" == "" ];then
		m="lua_shared_dict site_cache 64m;"
	fi
	wget -O  $speed_conf_file $download_Url/install/plugin/site_speed/speed.conf -T 5
	sed -i "s/^lua_shared_dict.*/$m/" $speed_conf_file

	wget -O $sp_path/cookie.lua $download_Url/install/plugin/site_speed/speed/cookie.lua -T 5
	wget -O $sp_path/ffi-zlib.lua $download_Url/install/plugin/site_speed/speed/ffi-zlib.lua -T 5
	wget -O $sp_path/speed.lua $download_Url/install/plugin/site_speed/speed/speed.lua -T 5
	wget -O $sp_path/nginx_get.lua $download_Url/install/plugin/site_speed/speed/nginx_get.lua -T 5
	wget -O $sp_path/nginx_set.lua $download_Url/install/plugin/site_speed/speed/nginx_set.lua -T 5
	wget -O $sp_path/httpd_speed.lua $download_Url/install/plugin/site_speed/speed/httpd_speed.lua -T 5
	wget -O $sp_path/memcached.lua $download_Url/install/plugin/site_speed/speed/memcached.lua -T 5
	wget -O $sp_path/CRC32.lua $download_Url/install/plugin/site_speed/speed/CRC32.lua -T 5
	speed_conf_file=/www/server/panel/vhost/apache/speed.conf
	wget -O  $speed_conf_file $download_Url/install/plugin/site_speed/speed_httpd.conf -T 5
	if [ ! -f $sp_path/config.lua ];then
		wget -O $sp_path/config.lua $download_Url/install/plugin/site_speed/speed/config.lua -T 5
	fi

	ng_waf_file=/www/server/panel/vhost/nginx/btwaf.conf
	if [ -f $ng_waf_file ];then
		sed -i "s/^body_filter_by_lua_file/#body_filter_by_lua_file/" $ng_waf_file
	fi

	waf_file=/www/server/panel/vhost/apache/btwaf.conf
	if [ ! -f $waf_file ];then
		echo "LoadModule lua_module modules/mod_lua.so" > $waf_file
	fi
	chattr +i $waf_file
	mkdir -p /www/server/panel/plugin/btwaf_httpd

	site_cache_path=/www/server/panel/plugin/site_cache
	if [ -f $site_cache/info.json ];then
		wget -O $site_cache/install.sh $download_Url/install/plugin/site_cache/install.sh -T 5
		bash $site_cache/install.sh uninstall
	fi

	chown -R www:www $sp_path
	chmod -R 755 $sp_path

	if [ -f /etc/init.d/nginx ];then
		/etc/init.d/nginx reload
	else
		/etc/init.d/httpd reload
	fi
	echo > /www/server/panel/data/reload.pl
	echo 'The installation is complete' > $install_tmp
}



Uninstall_site_speed()
{
	rm -rf $pluginPath
	rm -rf /www/server/speed

	ng_waf_file=/www/server/panel/vhost/nginx/btwaf.conf
	if [ -f $ng_waf_file ];then
		sed -i "s/^#body_filter_by_lua_file/body_filter_by_lua_file/" $ng_waf_file 
	fi

	speed_conf_file=/www/server/panel/vhost/nginx/speed.conf
	if [ -f $speed_conf_file ];then
		rm -f $speed_conf_file
	fi

	speed_conf_file=/www/server/panel/vhost/apache/speed.conf
	if [ -f $speed_conf_file ];then
		rm -f $speed_conf_file
	fi

	if [ -f /etc/init.d/nginx ];then
		/etc/init.d/nginx reload
	else
		/etc/init.d/httpd reload
	fi
}

Install_gzip_mod()
{
	gzip_so=/www/server/speed/gzip.so
	if [ ! -f $gzip_so ];then
		set_include_path
		wget -O lua-gzip-master.zip $download_Url/src/lua-gzip-master.zip -T 20
		unzip lua-gzip-master.zip
		rm -f lua-gzip-master.zip
		cd lua-gzip-master
		make
		mkdir /www/server/speed
		\cp -arf gzip.so $gzip_so
		cd ..
		rm -rf lua-gzip-master
	fi
}

Install_cjson()
{
	if [ -f /usr/bin/yum ];then
		isInstall=`rpm -qa |grep lua-devel`
		if [ "$isInstall" == "" ];then
			yum install lua lua-devel -y
		fi
	else
		isInstall=`dpkg -l|grep liblua5.1-0-dev`
		if [ "$isInstall" == "" ];then
			apt-get install lua5.1 lua5.1-dev lua5.1-cjson lua5.1-socket -y
		fi
	fi

	Centos8Check=$(cat /etc/redhat-release | grep ' 8.' | grep -iE 'centos|Red Hat')
	if [ "${Centos8Check}" ];then
		yum install lua-socket -y
		if [ ! -f /usr/lib/lua/5.3/cjson.so ];then
			wget -O lua-5.3-cjson.tar.gz $download_Url/src/lua-5.3-cjson.tar.gz -T 20
			tar -xvf lua-5.3-cjson.tar.gz
			cd lua-5.3-cjson
			make
			make install
			ln -sf /usr/lib/lua/5.3/cjson.so /usr/lib64/lua/5.3/cjson.so
			cd ..
			rm -f lua-5.3-cjson.tar.gz
			rm -rf lua-5.3-cjson
			return
		fi
	fi

	if [ ! -f /usr/local/lib/lua/5.1/cjson.so ];then
		set_include_path
		wget -O lua-cjson-2.1.0.tar.gz $download_Url/install/src/lua-cjson-2.1.0.tar.gz -T 20
		tar xvf lua-cjson-2.1.0.tar.gz
		rm -f lua-cjson-2.1.0.tar.gz
		cd lua-cjson-2.1.0
		make clean
		make
		make install
		cd ..
		rm -rf lua-cjson-2.1.0
		ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/lib64/lua/5.1/cjson.so
		ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/lib/lua/5.1/cjson.so
	else
		if [ -d "/usr/lib64/lua/5.1" ];then
			ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/lib64/lua/5.1/cjson.so
		fi

		if [ -d "/usr/lib/lua/5.1" ];then
			ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/lib/lua/5.1/cjson.so
		fi
	fi
}


Install_socket()
{

	if [ ! -f /usr/local/lib/lua/5.1/socket/core.so ];then
		set_include_path
		wget -O luasocket-master.zip $download_Url/install/src/luasocket-master.zip -T 20
		unzip luasocket-master.zip
		rm -f luasocket-master.zip
		cd luasocket-master
		make
		make install
		cd ..
		rm -rf luasocket-master
	fi

	if [ ! -d /usr/share/lua/5.1/socket ]; then
		if [ -d /usr/lib64/lua/5.1 ];then
			rm -rf /usr/lib64/lua/5.1/socket /usr/lib64/lua/5.1/mime
			ln -sf /usr/local/lib/lua/5.1/socket /usr/lib64/lua/5.1/socket
			ln -sf /usr/local/lib/lua/5.1/mime /usr/lib64/lua/5.1/mime
		else
			rm -rf /usr/lib/lua/5.1/socket /usr/lib/lua/5.1/mime
			mkdir -p /usr/lib/lua/5.1/
			ln -sf /usr/local/lib/lua/5.1/socket /usr/lib/lua/5.1/socket
			ln -sf /usr/local/lib/lua/5.1/mime /usr/lib/lua/5.1/mime
		fi
		rm -rf /usr/share/lua/5.1/mime.lua /usr/share/lua/5.1/socket.lua /usr/share/lua/5.1/socket
		mkdir -p /usr/share/lua/5.1
		ln -sf /usr/local/share/lua/5.1/mime.lua /usr/share/lua/5.1/mime.lua
		ln -sf /usr/local/share/lua/5.1/socket.lua /usr/share/lua/5.1/socket.lua
		ln -sf /usr/local/share/lua/5.1/socket /usr/share/lua/5.1/socket
	fi
}

Install_mod_lua()
{
	if [ ! -f /www/server/apache/bin/httpd ];then
		return 0;
	fi

	if [ -f /www/server/apache/modules/mod_lua.so ];then
		return 0;
	fi
	cd /www/server/apache
	if [ ! -d /www/server/apache/src ];then
		wget -O httpd-2.4.33.tar.gz $download_Url/src/httpd-2.4.33.tar.gz -T 20
		tar xvf httpd-2.4.33.tar.gz
		rm -f httpd-2.4.33.tar.gz
		mv httpd-2.4.33 src
		cd /www/server/apache/src/srclib
		wget -O apr-1.6.3.tar.gz $download_Url/src/apr-1.6.3.tar.gz
		wget -O apr-util-1.6.1.tar.gz $download_Url/src/apr-util-1.6.1.tar.gz
		tar zxf apr-1.6.3.tar.gz
		tar zxf apr-util-1.6.1.tar.gz
		mv apr-1.6.3 apr
		mv apr-util-1.6.1 apr-util
	fi
	cd /www/server/apache/src
	./configure --prefix=/www/server/apache --enable-lua
	cd modules/lua
	make
	make install

	if [ ! -f /www/server/apache/modules/mod_lua.so ];then
		echo 'Mod lua installation failed!';
		exit 0;
	fi
}

set_include_path()
{
	if [ -d /usr/include/lua5.1 ];then
		C_INCLUDE_PATH=/usr/include/lua5.1/
		export C_INCLUDE_PATH
	fi
}


action=$1
if [ "${1}" == 'install' ];then
	Install_site_speed
else
	Uninstall_site_speed
fi
