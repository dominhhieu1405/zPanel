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
pluginPath=/www/server/panel/plugin/btwaf
remote_dir="total2"
pyVersion=$(python -c 'import sys;print(sys.version_info[0]);')
py_zi=$(python -c 'import sys;print(sys.version_info[1]);')
pluginPath2=/www/server/panel/plugin/webshell_san
aacher=$(uname -a |grep -Po aarch64|awk 'NR==1')
Centos6Check=$(cat /etc/redhat-release|grep ' 6.'|grep -i centos)


Get_platform()
{
    case $(uname -s 2>/dev/null) in
        Linux )                    echo "linux" ;;
        FreeBSD )                  echo "freebsd" ;;
        *BSD* )                    echo "bsd" ;;
        Darwin )                   echo "macosx" ;;
        CYGWIN* | MINGW* | MSYS* ) echo "mingw" ;;
        AIX )                      echo "aix" ;;
        SunOS )                    echo "solaris" ;;
        * )                        echo "unknown"
    esac
}
Remove_path()
{
    local prefix=$1
    local new_path
    new_path=$(echo "${PATH}" | sed \
        -e "s#${prefix}/[^/]*/bin[^:]*:##g" \
        -e "s#:${prefix}/[^/]*/bin[^:]*##g" \
        -e "s#${prefix}/[^/]*/bin[^:]*##g")
    export PATH="${new_path}"
}
Add_path()
{
    local prefix=$1
    local new_path
    new_path=$(echo "${PATH}" | sed \
        -e "s#${prefix}/[^/]*/bin[^:]*:##g" \
        -e "s#:${prefix}/[^/]*/bin[^:]*##g" \
        -e "s#${prefix}/[^/]*/bin[^:]*##g")
    export PATH="${prefix}:${new_path}"
}

Get_lua_version(){
    echo `lua -e 'print(_VERSION:sub(5))'`
}


Install_LuaJIT()
{	
	LUAJIT_VER="2.1.0-beta3"
	LUAJIT_INC_PATH="luajit-2.1"
	if [ ! -f '/usr/local/lib/libluajit-5.1.so' ] || [ ! -f "/usr/local/include/${LUAJIT_INC_PATH}/luajit.h" ];then
		wget -c -O LuaJIT-${LUAJIT_VER}.tar.gz ${download_Url}/install/src/LuaJIT-${LUAJIT_VER}.tar.gz -T 10
		tar xvf LuaJIT-${LUAJIT_VER}.tar.gz
		cd LuaJIT-${LUAJIT_VER}
		make linux
		make install
		cd ..
		rm -rf LuaJIT-*
		export LUAJIT_LIB=/usr/local/lib
		export LUAJIT_INC=/usr/local/include/${LUAJIT_INC_PATH}/
		ln -sf /usr/local/lib/libluajit-5.1.so.2 /usr/local/lib64/libluajit-5.1.so.2
		echo "/usr/local/lib" >> /etc/ld.so.conf
		ldconfig
	fi
}


Install_lua515(){
    local install_path="/www/server/btwaf/lua515"

    local version
    version=$(Get_lua_version)

    echo "Current lua version: "$version
    if  [ -d "${install_path}/bin" ]
    then
        Add_path "${install_path}/bin"
        echo "Lua 5.1.5 has installed."
		return 1
    fi

    local lua_version="lua-5.1.5"
    local package_name="${lua_version}.tar.gz"
    local url="http://download.bt.cn/install/plugin/${remote_dir}/"$package_name
    mkdir -p $install_path
    local tmp_dir=/tmp/$lua_version
    mkdir -p $tmp_dir && cd $tmp_dir
    wget $url
    tar xvzf $package_name
    cd $lua_version
    platform=$(Get_platform)
    if [ "${platform}" = "unknown" ]
    then
        platform="linux"
    fi
    make "${platform}" install INSTALL_TOP=$install_path
    Add_path "${install_path}/bin"
    cd /tmp && rm -rf "/tmp/${lua_version}*"

    version=$(Get_lua_version)
    if [ ${version} == "5.1" ]
    then
        echo "Lua 5.1.5 has installed."
        return 1
    fi
    return 0
}
Install_sqlite3_for_nginx()
{

    if [ true ];then
        rm -rf /tmp/luarocks-3.5.0.*
        wget -c -O /tmp/luarocks-3.5.0.tar.gz http://download.bt.cn/btwaf_rule_aapanel/package/luarocks-3.5.0.tar.gz  -T 10
        cd /tmp && tar xf /tmp/luarocks-3.5.0.tar.gz
	    cd /tmp/luarocks-3.5.0
	    ./configure --with-lua-include=/www/server/btwaf/lua515/include --with-lua-bin=/www/server/btwaf/lua515/bin
	    make -I/www/server/btwaf/lua515/bin
	    make install
	    cd .. && rm -rf /tmp/luarocks-3.5.0.*
    fi

    if [ true ];then
        yum install -y sqlite-devel
        apt install -y libsqlite3-dev
        rm -rf /tmp/lsqlite3_fsl09y*
        wget -c -O /tmp/lsqlite3_fsl09y.zip http://download.bt.cn/btwaf_rule_aapanel/package/lsqlite3_fsl09y.zip  -T 10
        cd /tmp && unzip /tmp/lsqlite3_fsl09y.zip && cd lsqlite3_fsl09y && make
        if [ ! -f '/tmp/lsqlite3_fsl09y/lsqlite3.so' ];then
            echo $tip9
            wget -c -o /www/server/btwaf/lsqlite3.so http://download.bt.cn/btwaf_rule_aapanel/package/lsqlite3.so -T 10
        else
            echo $tip10
            \cp -a -r /tmp/lsqlite3_fsl09y/lsqlite3.so /www/server/btwaf/lsqlite3.so
        fi
        rm -rf /tmp/lsqlite3_fsl09y
        rm -rf /tmp/lsqlite3_fsl09y.zip
    fi
    if [ -f /usr/local/lib/lua/5.1/cjson.so ];then
        is_jit_cjson=$(luajit -e "require 'cjson'" 2>&1|grep 'undefined symbol: luaL_setfuncs')
        if [ "$is_jit_cjson" != "" ];then
            cd /tmp
            luarocks install lua-cjson
        fi
    fi
}



Install_luarocks()
{
	if [ -f '/usr/include/lua.h' ];then
		include_path='/usr/include/'
	elif [ -f '/usr/local/include/luajit-2.1/lua.h' ];then
		include_path='/usr/local/include/luajit-2.1/'
	elif [ -f '/usr/include/lua5.1/' ];then
		include_path='/usr/include/lua5.1/'
	elif [ -f '/usr/local/include/luajit-2.0/' ];then
		include_path='/usr/local/include/luajit-2.0/'
	else
		include_path=''
	fi

	if [ -f '/usr/bin/lua' ];then
		lua_bin='/usr/bin/'
	elif [ -f '/usr/lib/lua' ];then
		lua_bin='/usr/lib/'
	elif [ -f '/usr/lib64/lua' ];then
		lua_bin='/usr/lib64/'
	else
		lua_bin='/usr/bin/'
	fi

	if [ ! -f '/usr/local/bin/luarocks' ];then
		rm -rf /tmp/luarocks-3.5.0.*
		wget -c -O /tmp/luarocks-3.5.0.tar.gz http://download.bt.cn/btwaf_rule_aapanel/package/luarocks-3.5.0.tar.gz  -T 10
		cd /tmp && tar xvf /tmp/luarocks-3.5.0.tar.gz &&  cd /tmp/luarocks-3.5.0 && ./configure --with-lua-bin=$lua_bin --with-lua-include=$include_path && make -I$include_path && sudo make install && cd .. && rm -rf luarocks-3.5.0.*
	fi
}
install_sql3()
{
	yum install sqlite-devel
	apt install libsqlite3-dev

	if [ ! -f '/www/server/btwaf/lsqlite3.so' ];then
		rm -rf /tmp/lsqlite3_fsl09y*
		wget -c -O /tmp/lsqlite3_fsl09y.zip $download_Url/btwaf_rule_aapanel/package/btwaf/lsqlite3_fsl09y.zip  -T 10
		cd /tmp && unzip /tmp/lsqlite3_fsl09y.zip && cd lsqlite3_fsl09y && make
		if [ ! -f '/tmp/lsqlite3_fsl09y/lsqlite3.so' ];then
			echo '解压不成功'
		else
			echo '解压成功'
			\cp -a -r /tmp/lsqlite3_fsl09y/lsqlite3.so /www/server/btwaf/lsqlite3.so
		fi
		rm -rf /tmp/lsqlite3_fsl09y
		rm -rf /tmp/lsqlite3_fsl09y.zip
	fi
}


install_mbd(){
	if [ ! -f '/www/server/btwaf/GeoLite2-City.mmdb' ];then
		wget -c -O /www/server/btwaf/GeoLite2-City.mmdb.tar.gz $download_Url/btwaf_rule_aapanel/package/GeoLite2-City.mmdb.tar.gz -T 10
		cd /www/server/btwaf/ && tar zxvf GeoLite2-City.mmdb.tar.gz
		rm -rf /www/server/btwaf/GeoLite2-City.mmdb.tar.gz
	fi
	if [ ! -f '/www/server/btwaf/GeoLite2-City.mmdb' ];then
		wget -c -O /www/server/btwaf/GeoLite2-City.mmdb $download_Url/btwaf_rule_aapanel/package/GeoLite2-City.mmdb -T 10
	fi
}


Install_white_ip()
{
cat >$pluginPath/white.py<< EOF
# coding: utf-8
import sys
sys.path.append('/www/server/panel/class')
import public, json
def ip2long(ip):
    ips = ip.split('.')
    if len(ips) != 4: return 0
    iplong = 2 ** 24 * int(ips[0]) + 2 ** 16 * int(ips[1]) + 2 ** 8 * int(ips[2]) + int(ips[3])
    return iplong
def zhuanhuang(aaa):
    ac = []
    cccc = 0
    list = []
    list2 = []
    for i in range(len(aaa)):
        for i2 in aaa[i]:
            dd = ''
            coun = 0
            for i3 in i2:
                if coun == 3:
                    dd += str(i3)
                else:
                    dd += str(i3) + '.'
                coun += 1
            list.append(ip2long(dd))
            cccc += 1
            if cccc % 2 == 0:
                aa = []
                bb = []
                aa.append(list[0])
                bb.append(list[1])
                cc = []
                cc.append(aa)
                cc.append(bb)
                ac.append(list)
                list = []
                list2 = []
    return ac
def main():
    try:
        aaa = json.loads(public.ReadFile("/www/server/btwaf/rule/ip_white.json"))
        if not aaa:return  False
        if type(aaa[0][0])==list:
            f = open('/www/server/btwaf/rule/ip_white.json', 'w')
            f.write(json.dumps(zhuanhuang(aaa)))
            f.close()
    except:
        public.writeFile("/www/server/btwaf/rule/ip_white.json", json.dumps([]))

    try:
        aaa = json.loads(public.ReadFile("/www/server/btwaf/rule/ip_black.json"))
        if not aaa: return False
        if type(aaa[0][0]) == list:
            f = open('/www/server/btwaf/rule/ip_black.json', 'w')
            f.write(json.dumps(zhuanhuang(aaa)))
            f.close()
    except:
        public.writeFile("/www/server/btwaf/rule/ip_black.json", json.dumps([]))
main()
print("转换ip格式")
EOF
}

install_static()
{
	mkdir $pluginPath/templates/
	mkdir $pluginPath/static/
	wget -O $pluginPath/templates/index.html $download_Url/btwaf_rule_aapanel/templates/index.html -T 5
	wget -O $pluginPath/templates/error4.html $download_Url/btwaf_rule_aapanel/templates/error4.html -T 5
	rm -rf $pluginPath/static/*
	wget -O $pluginPath/static/static.zip $download_Url/btwaf_rule_aapanel/static/static.zip
	unzip -o $pluginPath/static/static.zip -d $pluginPath/ > /dev/null
	rm -rf $pluginPath/static/static.zip
}


Install_btwaf()
{ 
	if [ -f /www/server/btwaf/httpd.lua ];then
		rm -rf /www/server/btwaf
	fi
	en=''
	grep "English" /www/server/panel/config/config.json >> /dev/null
	if [ "$?" -eq 0 ];then
		en='_en'
	fi
	usranso2=`ls -l /usr/local/lib/lua/5.1/cjson.so | awk '{print $5}'`
	if [ $usranso2 -eq 0 ];then
		rm -rf /usr/local/lib/lua/5.1/cjson.so
	fi
	rm -rf /www/server/panel/vhost/nginx/free_waf.conf
	rm -rf /www/server/free_waf
	rm -rf /www/server/panel/plugin/free_waf
	yum install sqlite-devel
	apt install sqlite-devel
	#Install_socket
	mkdir $pluginPath2
	mkdir -p $pluginPath
	wget -O $pluginPath/firewalls_list.py $download_Url/btwaf_rule_aapanel/bt_waf/firewalls_list.py -T 5
	yum install lua-socket -y
	yum install lua-json -y 
	apt-get install lua-socket -y
	apt-get install lua-cjson -y
	Install_cjson
	#Install_luarocks
	Install_lua515
	Install_sqlite3_for_nginx
	echo '正在安装脚本文件...' > $install_tmp


	install_static
	if [ "$aacher" == "aarch64" ];then
		if [  -f /www/server/panel/pyenv/bin/python ];then
			wget -O $pluginPath/btwaf_main.cpython-37m-aarch64-linux-gnu.zip $download_Url/btwaf_rule_aapanel/bt_waf/aachar64/btwaf_main.cpython-37m-aarch64-linux-gnu.zip -T 5
			unzip -o $pluginPath/btwaf_main.cpython-37m-aarch64-linux-gnu.zip -d $pluginPath > /dev/null
			rm -rf $pluginPath/btwaf_main.cpython-37m-aarch64-linux-gnu.zip
		else
			if [ "$pyVersion" == 2 ];then
				wget -O $pluginPath/btwaf_main.zip $download_Url/btwaf_rule_aapanel/bt_waf/aachar64/btwaf_main.zip -T 5
				unzip -o $pluginPath/btwaf_main.zip -d $pluginPath > /dev/null
				rm -rf $pluginPath/btwaf_main.zip
			else
				if [ "$py_zi" == 6 ];then 
					wget -O $pluginPath/btwaf_main.cpython-36m-aarch64-linux-gnu.zip $download_Url/btwaf_rule_aapanel/bt_waf/aachar64/btwaf_main.cpython-36m-aarch64-linux-gnu.zip -T 5
					unzip -o $pluginPath/btwaf_main.cpython-36m-aarch64-linux-gnu.zip -d $pluginPath > /dev/null
					rm -rf $pluginPath/btwaf_main.cpython-36m-aarch64-linux-gnu.zip
				fi 
				if [ "$py_zi" == 7 ];then 
					wget -O $pluginPath/btwaf_main.cpython-37m-aarch64-linux-gnu.zip $download_Url/btwaf_rule_aapanel/bt_waf/aachar64/btwaf_main.cpython-37m-aarch64-linux-gnu.zip -T 5
					unzip -o $pluginPath/btwaf_main.cpython-37m-aarch64-linux-gnu.zip -d $pluginPath > /dev/null
					rm -rf $pluginPath/btwaf_main.cpython-37m-aarch64-linux-gnu.zip
				fi
			fi
		fi	
	else
		if [  -f /www/server/panel/pyenv/bin/python ];then
			wget -O $pluginPath/btwaf_main.cpython-37m-x86_64-linux-gnu.zip $download_Url/btwaf_rule_aapanel/bt_waf/8.9.0/btwaf_main.cpython-37m-x86_64-linux-gnu$en.zip -T 5
			
			unzip -o $pluginPath/btwaf_main.cpython-37m-x86_64-linux-gnu.zip -d $pluginPath > /dev/null
			rm -rf $pluginPath/btwaf_main.cpython-37m-x86_64-linux-gnu.zip
		else
			if [ "$pyVersion" == 2 ];then
				wget -O $pluginPath/btwaf_main.zip $download_Url/btwaf_rule_aapanel/bt_waf/8.9.0/btwaf_main$en.zip -T 5
				unzip -o $pluginPath/btwaf_main.zip -d $pluginPath > /dev/null
				rm -rf $pluginPath/btwaf_main.zip
			else
				if [ "$py_zi" == 6 ];then 
					wget -O $pluginPath/btwaf_main.cpython-36m-x86_64-linux-gnu.zip $download_Url/btwaf_rule_aapanel/bt_waf/8.9.0/btwaf_main.cpython-36m-x86_64-linux-gnu$en.zip -T 5
					unzip -o $pluginPath/btwaf_main.cpython-36m-x86_64-linux-gnu.zip -d $pluginPath > /dev/null
					rm -rf $pluginPath/btwaf_main.cpython-36m-x86_64-linux-gnu.zip
				fi 
				if [ "$py_zi" == 4 ];then 
					wget -O $pluginPath/btwaf_main.cpython-34m.zip $download_Url/btwaf_rule/test/btwaf/btwaf_main.cpython-34m$en.zip -T 5
					unzip -o $pluginPath/btwaf_main.cpython-34m.zip -d $pluginPath > /dev/null
					rm -rf $pluginPath/btwaf_main.cpython-34m.zip
				fi
				if [ "$py_zi" == 7 ];then 
					wget -O $pluginPath/btwaf_main.cpython-37m-x86_64-linux-gnu.zip $download_Url/btwaf_rule_aapanel/bt_waf/8.9.0/btwaf_main.cpython-37m-x86_64-linux-gnu$en.zip -T 5
					unzip -o $pluginPath/btwaf_main.cpython-37m-x86_64-linux-gnu.zip -d $pluginPath > /dev/null
					rm -rf $pluginPath/btwaf_main.cpython-37m-x86_64-linux-gnu.zip
				fi
			fi
		fi
	fi

	wget -O $pluginPath/btwaf_main.zip $download_Url/btwaf_rule_aapanel/bt_waf/8.9.0/btwaf_main$en.zip -T 5
	wget -O $pluginPath/totle_db.py $download_Url/btwaf_rule_aapanel/bt_waf/8.9.0/totle_db.py -T 5
	wget -O $pluginPath/totle_db2.py $download_Url/btwaf_rule_aapanel/bt_waf/8.9.0/totle_db2.py -T 5

	unzip -o $pluginPath/btwaf_main.zip -d $pluginPath > /dev/null
	rm -rf $pluginPath/btwaf_main.zip
	wget -O $pluginPath/webshell_check.py $download_Url/btwaf_rule_aapanel/bt_waf/webshell_check.py -T 5
	wget -O $pluginPath/btwaf_main.py $download_Url/btwaf_rule_aapanel/bt_waf/btwaf_main.py -T 5
	wget -O $pluginPath/send_vilidate.py $download_Url/btwaf_rule_aapanel/bt_waf/send_vilidate.py -T 5
	#wget -O $pluginPath/white.py $download_Url/btwaf_rule/test/btwaf/8.7.1/white.py -T 5
	Install_white_ip
	python $pluginPath/send_vilidate.py
	if [ ! -f /www/server/btwaf/captcha/num2.json ];then
		wget -O /www/server/btwaf/captcha.zip $download_Url/btwaf_rule_aapanel/bt_waf/captcha.zip -T 5
		unzip -o /www/server/btwaf/captcha.zip  -d /www/server/btwaf/ > /dev/null
		rm -rf /www/server/btwaf/captcha.zip
	fi
	wget -O $pluginPath/firewalls_list.py $download_Url/btwaf_rule_aapanel/bt_waf/firewalls_list.py -T 5
	wget -O $pluginPath/index.html $download_Url/btwaf_rule_aapanel/bt_waf/8.7.1/index$en.html -T 5
	wget -O $pluginPath/info.json $download_Url/btwaf_rule_aapanel/bt_waf/info$en.json -T 5
	wget -O $pluginPath/icon.png $download_Url/btwaf_rule_aapanel/bt_waf/icon.png -T 5
	wget -O $pluginPath/rule.json $download_Url/btwaf_rule_aapanel/bt_waf/rule.json -T 5
	if [ ! -f /www/server/panel/vhost/nginx/speed.conf ];then
		wget -O /www/server/panel/vhost/nginx/btwaf.conf $download_Url/btwaf_rule_aapanel/bt_waf/btwaf.conf -T 5
	else
		wget -O /www/server/panel/vhost/nginx/btwaf.conf $download_Url/btwaf_rule_aapanel/bt_waf/btwaf2.conf -T 5
	fi
	wget -O $pluginPath2/webshell_san_main.py $download_Url/btwaf_rule_aapanel/bt_waf/webshell_san_main.py -T 5
	\cp -a -r /www/server/panel/plugin/btwaf/icon.png /www/server/panel/static/img/soft_ico/ico-btwaf.png
	wget -O $pluginPath/btwaf.zip $download_Url/btwaf_rule_aapanel/bt_waf/btwaf$en.zip -T 5
	unzip -o $pluginPath/btwaf.zip -d /tmp/ > /dev/null
	rm -f $pluginPath/btwaf.zip
	btwaf_path=/www/server/btwaf
	mkdir -p $btwaf_path/html
	rm -rf /www/server/btwaf/cms
	mv /tmp/btwaf/cms/  $btwaf_path
	
	if [ ! -f $btwaf_path/html/url.html ];then
		\cp -a -r /tmp/btwaf/html/url.html $btwaf_path/html/url.html
		\cp -a -r /tmp/btwaf/html/ip.html $btwaf_path/html/ip.html
	fi

	if [ ! -f $btwaf_path/html/get.html ];then
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/get.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/post.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/cookie.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/user_agent.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/other.html
	fi
	mkdir -p $btwaf_path/rule
	\cp -a -r /tmp/btwaf/rule/cn.json $btwaf_path/rule/cn.json
	\cp -a -r /tmp/btwaf/rule/lan.json $btwaf_path/rule/lan.json

	if [ ! -f $btwaf_path/rule/post.json ];then
		\cp -a -r /tmp/btwaf/rule/url.json $btwaf_path/rule/url.json
		\cp -a -r /tmp/btwaf/rule/args.json $btwaf_path/rule/args.json
		\cp -a -r /tmp/btwaf/rule/post.json $btwaf_path/rule/post.json
		\cp -a -r /tmp/btwaf/rule/cookie.json $btwaf_path/rule/cookie.json
		\cp -a -r /tmp/btwaf/rule/head_white.json $btwaf_path/rule/head_white.json
		\cp -a -r /tmp/btwaf/rule/user_agent.json $btwaf_path/rule/user_agent.json
		\cp -a -r /tmp/btwaf/rule/cn.json $btwaf_path/rule/cn.json
		\cp -a -r /tmp/btwaf/rule/ip_white.json $btwaf_path/rule/ip_white.json
		\cp -a -r /tmp/btwaf/rule/scan_black.json $btwaf_path/rule/scan_black.json
		\cp -a -r /tmp/btwaf/rule/url_black.json $btwaf_path/rule/url_black.json
		\cp -a -r /tmp/btwaf/rule/ip_black.json $btwaf_path/rule/ip_black.json
		\cp -a -r /tmp/btwaf/rule/url_white.json $btwaf_path/rule/url_white.json
		\cp -a -r /tmp/btwaf/1.json $btwaf_path/1.json
		\cp -a -r /tmp/btwaf/2.json $btwaf_path/2.json
		\cp -a -r /tmp/btwaf/3.json $btwaf_path/3.json
		\cp -a -r /tmp/btwaf/4.json $btwaf_path/4.json
		\cp -a -r /tmp/btwaf/5.json $btwaf_path/5.json
		\cp -a -r /tmp/btwaf/6.json $btwaf_path/6.json
		\cp -a -r /tmp/btwaf/zhi.json $btwaf_path/zhi.json
	fi
	\cp -a -r /tmp/btwaf/1.json $btwaf_path/1.json
	\cp -a -r /tmp/btwaf/2.json $btwaf_path/2.json
	\cp -a -r /tmp/btwaf/3.json $btwaf_path/3.json
	\cp -a -r /tmp/btwaf/4.json $btwaf_path/4.json
	\cp -a -r /tmp/btwaf/5.json $btwaf_path/5.json
	\cp -a -r /tmp/btwaf/6.json $btwaf_path/6.json
	\cp -a -r /tmp/btwaf/7.json $btwaf_path/7.json
	\cp -a -r /tmp/btwaf/zhi.json $btwaf_path/zhi.json
	if [ ! -f $btwaf_path/webshell.json ];then
		\cp -a -r /tmp/btwaf/webshell.json $btwaf_path/webshell.json
	fi
	
	if [ ! -f $btwaf_path/webshell_url.json ];then
		\cp -a -r /tmp/btwaf/webshell_url.json $btwaf_path/webshell_url.json
	fi
	
	if [ ! -f $btwaf_path/shell_check.json ];then
		\cp -a -r /tmp/btwaf/shell_check.json $btwaf_path/shell_check.json
	fi
	
	if [ ! -f $btwaf_path/rule/cc_uri_white.json ];then
		\cp -a -r /tmp/btwaf/rule/cc_uri_white.json $btwaf_path/rule/cc_uri_white.json
	fi
	
	if [ ! -f /dev/shm/stop_ip.json ];then
		\cp -a -r /tmp/btwaf/stop_ip.json /dev/shm/stop_ip.json
	fi
	chmod 777 /dev/shm/stop_ip.json
	chown www:www /dev/shm/stop_ip.json
	
	
	if [ ! -f $btwaf_path/site.json ];then
		\cp -a -r /tmp/btwaf/site.json $btwaf_path/site.json
	fi
	
	if [ ! -f $btwaf_path/config.json ];then
		\cp -a -r /tmp/btwaf/config.json $btwaf_path/config.json
	fi
	
	if [ ! -f $btwaf_path/domains.json ];then
		\cp -a -r /tmp/btwaf/domains.json $btwaf_path/domains.json
	fi
	
	if [ ! -f $btwaf_path/total.json ];then
		\cp -a -r /tmp/btwaf/total.json $btwaf_path/total.json
	fi
	
	if [ ! -f $btwaf_path/drop_ip.log ];then
		
		\cp -a -r /tmp/btwaf/drop_ip.log $btwaf_path/drop_ip.log
	fi
	\cp -a -r /tmp/btwaf/zhi.lua $btwaf_path/zhi.lua
	if [ ! -b /www/server/btwaf/captcha/num2.json ];then
		\cp -a -r /tmp/btwaf/10.59.lua $btwaf_path/init.lua
		
	else 
		\cp -a -r /tmp/btwaf/8.8.lua $btwaf_path/init.lua
	fi
	\cp -a -r /tmp/btwaf/libinjection.lua $btwaf_path/libinjection.lua
	
	\cp -a -r /tmp/btwaf/multipart.lua $btwaf_path/multipart.lua
	if [ ! -n "$Centos6Check" ]; then
		\cp -a -r /tmp/btwaf/libinjection_2021_02_20.so $btwaf_path/libinjection.so
	else
		\cp -a -r /tmp/btwaf/centos6_libinjection.so $btwaf_path/libinjection.so
	fi
	\cp -a -r /tmp/btwaf/header.lua $btwaf_path/header.lua
	\cp -a -r /tmp/btwaf/ffijson.lua $btwaf_path/ffijson.lua
	\cp -a -r /tmp/btwaf/dns.lua $btwaf_path/dns.lua
	\cp -a -r /tmp/btwaf/body_lua2.lua $btwaf_path/body.lua
	\cp -a -r /tmp/btwaf/waf.lua $btwaf_path/waf.lua
	\cp -a -r /tmp/btwaf/maxminddb.lua $btwaf_path/maxminddb.lua
	\cp -a -r /tmp/btwaf/libmaxminddb.so $btwaf_path/libmaxminddb.so
	chmod +x $btwaf_path/waf.lua
	chmod +x $btwaf_path/init.lua
	mkdir -p /www/wwwlogs/btwaf
	chmod 777 /www/wwwlogs/btwaf
	chmod -R 755 /www/server/btwaf
	chmod -R 644 /www/server/btwaf/rule
	chmod -R 666 /www/server/btwaf/total.json
	chmod -R 666 /www/server/btwaf/drop_ip.log
	echo '' > /www/server/nginx/conf/luawaf.conf
	chown -R root:root /www/server/btwaf/
	chown www:www /www/server/btwaf/*.json
	chown www:www /www/server/btwaf/drop_ip.log
	install_mbd
	#Install_sqlite3_for_nginx
	mkdir /www/server/btwaf/total
	chown www:www /www/server/btwaf/total
	mkdir -p /www/server/btwaf/totla_db/http_log
	chown www:www /www/server/btwaf/totla_db/http_log
	chown www:www /www/server/btwaf/totla_db/

	/usr/bin/python $pluginPath/white.py
	python $pluginPath/white.py
	btpython $pluginPath/white.py
	
	if [ "$aacher" == "aarch64" ];then
		rm -rf /www/server/btwaf/libinjection.so
		\cp -a -r /tmp/btwaf/libinjection_arm.so /www/server/btwaf/libinjection.so
		#rm -rf cp  $btwaf_path/init.lua
		#cp -a -r /tmp/btwaf/xiu34.lua $btwaf_path/init.lua
	fi
	#Install_sqlite3_for_nginx
	chown www:www /www/server/btwaf/totla_db/totla_db.db
	if [ -n "$Centos6Check" ]; then
		\cp -a -r /tmp/btwaf/centos6.lua $btwaf_path/init.lua
	fi
	/etc/init.d/nginx restart
	sleep 2
	para5=$(ps -aux |grep nginx |grep  /www/server/nginx/conf/nginx.conf | awk 'NR==2')
	if [ ! -n "$para5" ]; then
		/etc/init.d/nginx restart
	fi
	sleep 2
	para1=$(ps -aux |grep nginx |grep  /www/server/nginx/conf/nginx.conf | awk 'NR==2')
	parc2=$(netstat -nltp|grep nginx| grep 80|wc -l)

	if [ ! -n "$para1" ]; then
		if [ $parc2 -eq 0 ]; then 
			rm -f /usr/local/lib/lua/5.1/cjson.so
			Install_cjson
			rm -rf /www/server/btwaf/init.lua
			echo 'Under repair...'
			Install_LuaJIT
			Install_sqlite3_for_nginx
			luarocks install lua-cjson
			\cp -a -r /tmp/btwaf/10.59.lua $btwaf_path/init.lua
			/etc/init.d/nginx restart
			para1=$(ps -aux |grep nginx |grep  /www/server/nginx/conf/nginx.conf | awk 'NR==2')
			parc2=$(netstat -nltp|grep nginx| grep 80|wc -l)
			if [ ! -n "$para1" ]; then 
				if [ $parc2 -eq 0 ]; then 
					cp -a -r /tmp/btwaf/xiu34.lua $btwaf_path/init.lua
					/etc/init.d/nginx restart
				fi
			fi
		fi
	fi

	rm -rf /tmp/btwaf
	chmod 755 /www/server/btwaf/rule
	chmod 755 /www/server/btwaf/
	chown www:www -R /www/server/btwaf/totla_db/
	chown www:www -R /www/server/btwaf/total/
	bash /www/server/panel/init.sh start
	echo > /www/server/panel/data/restart.pl
	echo '安装完成' > $install_tmp
}

Upload_btwaf()
{
  en=''
	grep "English" /www/server/panel/config/config.json >> /dev/null
	if [ "$?" -eq 0 ];then
		en='_en'
	fi
	mkdir $pluginPath2
	wget -O $pluginPath/firewalls_list.py http://download.bt.cn/btwaf_rule_aapanel/bt_waf/firewalls_list.py -T 5
	echo '正在安装脚本文件...' > $install_tmp
	if [ "$pyVersion" == 2 ];then
		wget -O $pluginPath/btwaf_main.zip $download_Url/btwaf_rule_aapanel/bt_waf/btwaf_main$en.zip -T 5
		unzip -o $pluginPath/btwaf_main.zip -d $pluginPath > /dev/null
		rm -rf $pluginPath/btwaf_main.zip
	else
		wget -O $pluginPath/btwaf_main.cpython-34m.zip $download_Url/btwaf_rule_aapanel/bt_waf/btwaf_main.cpython-34m$en.zip -T 5
		unzip -o $pluginPath/btwaf_main.cpython-34m.zip -d $pluginPath > /dev/null
		rm -rf $pluginPath/btwaf_main.cpython-34m.zip
		wget -O $pluginPath/btwaf_main.cpython-36m-x86_64-linux-gnu.zip $download_Url/btwaf_rule_aapanel/bt_waf/btwaf_main.cpython-36m-x86_64-linux-gnu$en.zip -T 5
		unzip -o $pluginPath/btwaf_main.cpython-36m-x86_64-linux-gnu.zip -d $pluginPath > /dev/null
		rm -rf $pluginPath/btwaf_main.cpython-36m-x86_64-linux-gnu.zip
	fi
	wget -O $pluginPath/rule.json $download_Url/btwaf_rule_aapanel/bt_waf/rule.json -T 5
	wget -O $pluginPath/send_vilidate.py $download_Url/btwaf_rule_aapanel/bt_waf/send_vilidate.py -T 5
	python $pluginPath/send_vilidate.py
	wget -O $pluginPath2/webshell_san_main.py $download_Url/btwaf_rule_aapanel/bt_waf/webshell_san_main.py -T 5
	wget -O $pluginPath/btwaf_main.py $download_Url/btwaf_rule_aapanel/bt_waf/btwaf_main.py -T 5
	wget -O $pluginPath/firewalls_list.py $download_Url/btwaf_rule_aapanel/bt_waf/firewalls_list.py -T 5
	wget -O $pluginPath/index.html $download_Url/btwaf_rule_aapanel/bt_waf/index$en.html -T 5
	wget -O $pluginPath/info.json $download_Url/btwaf_rule_aapanel/bt_waf/info$en.json -T 5
	wget -O $pluginPath/icon.png $download_Url/btwaf_rule_aapanel/bt_waf/icon.png -T 5
	wget -O /www/server/panel/vhost/nginx/btwaf.conf $download_Url/btwaf_rule_aapanel/bt_waf/btwaf.conf -T 5
	\cp -a -r /www/server/panel/plugin/btwaf/icon.png /www/server/panel/static/img/soft_ico/ico-btwaf.png
	wget -O $pluginPath/btwaf.zip $download_Url/btwaf_rule_aapanel/bt_waf/btwaf$en.zip -T 5
	unzip -o $pluginPath/btwaf.zip -d /tmp/ > /dev/null
	rm -f $pluginPath/btwaf.zip
	mkdir -p $btwaf_path/rule
	btwaf_path=/www/server/btwaf
	mkdir -p $btwaf_path/html
	rm -rf /www/server/btwaf/cms
	mv /tmp/btwaf/cms/  $btwaf_path
	
	if [ ! -f $btwaf_path/html/get.html ];then
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/get.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/post.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/cookie.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/user_agent.html
		\cp -a -r /tmp/btwaf/html/get.html $btwaf_path/html/other.html
	fi

	if [ ! -f $btwaf_path/rule/url.json ];then
		\cp -a -r /tmp/btwaf/rule/url.json $btwaf_path/rule/url.json
		\cp -a -r /tmp/btwaf/rule/args.json $btwaf_path/rule/args.json
		\cp -a -r /tmp/btwaf/rule/post.json $btwaf_path/rule/post.json
		\cp -a -r /tmp/btwaf/rule/cn.json $btwaf_path/rule/cn.json
		\cp -a -r /tmp/btwaf/rule/cookie.json $btwaf_path/rule/cookie.json
		\cp -a -r /tmp/btwaf/rule/head_white.json $btwaf_path/rule/head_white.json
		\cp -a -r /tmp/btwaf/rule/ip_black.json $btwaf_path/rule/ip_black.json
		\cp -a -r /tmp/btwaf/rule/ip_white.json $btwaf_path/rule/ip_white.json
		\cp -a -r /tmp/btwaf/rule/scan_black.json $btwaf_path/rule/scan_black.json
		\cp -a -r /tmp/btwaf/rule/url_black.json $btwaf_path/rule/url_black.json
		\cp -a -r /tmp/btwaf/rule/url_white.json $btwaf_path/rule/url_white.json
		\cp -a -r /tmp/btwaf/rule/user_agent.json $btwaf_path/rule/user_agent.json
		\cp -a -r /tmp/btwaf/rule/cc_uri_white.json $btwaf_path/rule/cc_uri_white.json
		\cp -a -r /tmp/btwaf/zhi.json $btwaf_path/zhi.json
	fi
	
	if [ ! -f $btwaf_path/webshell.json ];then
		\cp -a -r /tmp/btwaf/webshell.json $btwaf_path/webshell.json
	fi
	
	if [ ! -f $btwaf_path/webshell_url.json ];then
		\cp -a -r /tmp/btwaf/webshell_url.json $btwaf_path/webshell_url.json
	fi
	
	
	if [ ! -f $btwaf_path/rule/cc_uri_white.json ];then
		\cp -a -r /tmp/btwaf/rule/cc_uri_white.json $btwaf_path/rule/cc_uri_white.json
	fi
	
	if [ ! -f /dev/shm/stop_ip.json ];then
		\cp -a -r /tmp/btwaf/stop_ip.json /dev/shm/stop_ip.json
	fi
	chmod 777 /dev/shm/stop_ip.json
	chown www:www /dev/shm/stop_ip.json
	
	
	if [ ! -f $btwaf_path/site.json ];then
		\cp -a -r /tmp/btwaf/site.json $btwaf_path/site.json
	fi
	
	if [ ! -f $btwaf_path/config.json ];then
		\cp -a -r /tmp/btwaf/config.json $btwaf_path/config.json
	fi
	
	if [ ! -f $btwaf_path/total.json ];then
		\cp -a -r /tmp/btwaf/total.json $btwaf_path/total.json
	fi
	
	if [ ! -f $btwaf_path/drop_ip.log ];then
		\cp -a -r /tmp/btwaf/drop_ip.log $btwaf_path/drop_ip.log
	fi
	if [ ! -b  /www/server/btwaf/captcha/num2.json ];then
		\cp -a -r /tmp/btwaf/9.1.lua $btwaf_path/init.lua
	else 
		\cp -a -r /tmp/btwaf/xiu29.lua $btwaf_path/init.lua
	fi
	\cp -a -r /tmp/btwaf/body_lua2.lua $btwaf_path/body.lua
	\cp -a -r /tmp/btwaf/waf.lua $btwaf_path/waf.lua
	chmod +x $btwaf_path/waf.lua
	chmod +x $btwaf_path/init.lua
	mkdir /www/server/btwaf/total
	chown www:www /www/server/btwaf/total
	mkdir -p /www/wwwlogs/btwaf
	chmod 777 /www/wwwlogs/btwaf
	chmod -R 755 /www/server/btwaf
	chmod -R 666 /www/server/btwaf/total.json
	chmod -R 666 /www/server/btwaf/drop_ip.log

	echo '' > /www/server/nginx/conf/luawaf.conf
	\cp -a -r /tmp/btwaf/rule/cn.json $btwaf_path/rule/cn.json

	rm -rf /tmp/btwaf
	/etc/init.d/nginx reload
	bash /www/server/panel/init.sh start
	echo > /www/server/panel/data/restart.pl
	echo 'The installation is complete' > $install_tmp
}


Install_cjson()
{
	Install_LuaJIT
	if [ -f /usr/bin/yum ];then
		isInstall=`rpm -qa |grep lua-devel`
		if [ "$isInstall" == "" ];then
			yum install lua lua-devel -y
			yum install lua-socket -y
		fi
	else
		isInstall=`dpkg -l|grep liblua5.1-0-dev`
		if [ "$isInstall" == "" ];then
			apt-get install lua5.1 lua5.1-dev -y
		fi
	fi

	if [ -f /usr/local/lib/lua/5.1/cjson.so ];then
			is_jit_cjson=$(luajit -e "require 'cjson'" 2>&1|grep 'undefined symbol: luaL_setfuncs')
			if [ "$is_jit_cjson" != "" ];then
				rm -f /usr/local/lib/lua/5.1/cjson.so
			fi
	fi


	if [ ! -f /usr/local/lib/lua/5.1/cjson.so ];then
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
    #rm -rf /usr/local/lib/lua/5.1/socket/core.so 
	if [ ! -f /usr/local/lib/lua/5.1/socket/core.so ];then
		wget -O luasocket-master.zip $download_Url/install/src/luasocket-master.zip -T 20
		unzip luasocket-master.zip
		rm -f luasocket-master.zip
		cd luasocket-master
		export C_INCLUDE_PATH=/usr/local/include/luajit-2.0:$C_INCLUDE_PATH
		make
		make install
		cd ..
		rm -rf luasocket-master
	fi
	rm -rf /usr/share/lua/5.1/socket

	if [ ! -d /usr/share/lua/5.1/socket ]; then
		if [ -d /usr/lib64/lua/5.1 ];then
			mkdir /usr/lib64/lua/5.1/
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
		mkdir -p /usr/share/lua/5.1/ 
		mkdir -p /www/server/btwaf/
		ln -sf /usr/local/share/lua/5.1/mime.lua /usr/share/lua/5.1/mime.lua
		ln -sf /usr/local/share/lua/5.1/socket.lua /usr/share/lua/5.1/socket.lua
		ln -sf /usr/local/share/lua/5.1/socket /usr/share/lua/5.1/socket
		
		ln -sf /usr/local/share/lua/5.1/mime.lua /www/server/btwaf/mime.lua
		ln -sf /usr/local/share/lua/5.1/socket.lua /www/server/btwaf/socket.lua
		ln -sf /usr/local/share/lua/5.1/socket /www/server/btwaf/socket	
	fi
}

Uninstall_btwaf()
{
	rm -rf /www/server/panel/static/btwaf
	rm -f /www/server/panel/vhost/nginx/btwaf.conf
	rm -rf /www/server/panel/plugin/btwaf/
	rm -rf /usr/local/lib/lua/5.1/cjson.so
	rm -rf /www/server/btwaf/lsqlite3.so
	/etc/init.d/nginx reload
}

Check_install(){
if [ ! -d /www/server/btwaf/socket ]; then
	Install_btwaf
fi

}


if [ "${1}" == 'install' ];then
	Install_btwaf
elif  [ "${1}" == 'update' ];then
	Upload_btwaf
elif [ "${1}" == 'uninstall' ];then
	Uninstall_btwaf
fi