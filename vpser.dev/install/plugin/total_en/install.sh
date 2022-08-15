#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
install_tmp='/tmp/bt_install.pl'
public_file=/www/server/panel/install/public.sh
#安装脚本概述
#经过不同的用户安装环境测试，整理安装脚本安装逻辑如下：
#Web Server: nginx, apache
#lua版本: 5.1.4 5.1.5 5.3.1
#OS: CentOS7 CentOS8
#
#nginx和apache单独分开安装逻辑:
#
#因为面板的nginx是固定编译了lua5.1.5，所以nginx的安装统一会安装一个独立的lua5.1.5版本到/www/server/total/lu515,
#用来编译安装luarocks和lsqlite3。
#
#apache的编译跟随OS自带的Lua版本，所以apache默认不安装lua515环境。
#
#所有版本共用一个的lua脚本，已经从lua代码层面解决5.1~5.3的语法不同之处。

if [ ! -f $public_file ];then
        wget -O $public_file http://en.zpanel.cc/install/public.sh -T 5;
fi

download_Url=""
if [ ! "${1}" == 'uninstall' ];then
    . $public_file
    download_Url=$NODE_URL
fi
pluginPath=/www/server/panel/plugin/total
total_path=/www/server/total
remote_dir="total2_en"

wrong_actions=()
# Retry Download file
download_file()
{
    local_file=$1
    source=$2
    timeout=$3
    retry=$4
    if [ -n "$5" ]; then
        ori_retry=$5
    else
        ori_retry=$retry
    fi
    #echo "source:$source/local:$local_file/retry:$retry/ori_retry:$ori_retry"
    wget -O $local_file $source -T $timeout -t $ori_retry
    if [ -s $local_file ]; then
        echo $local_file" download successful."
    else
        if [ $retry -gt 1 ];then
            let retry=retry-1
            download_file $local_file $source $timeout $retry $ori_retry
        else
            echo "* "$local_file" download failed!"
            wrong_actions[${#wrong_actions[*]}]=$local_file
        fi
    fi
}

# Returns the platform
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

Install_lua515(){
    local install_path="/www/server/total/lua515"
    
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
    # wget $url
    download_file $package_name $url 10 3
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
        # wget -c -O /tmp/luarocks-3.5.0.tar.gz http://download.bt.cn/btwaf_rule/test/btwaf/luarocks-3.5.0.tar.gz  -T 10
        download_file /tmp/luarocks-3.5.0.tar.gz http://download.bt.cn/btwaf_rule/test/btwaf/luarocks-3.5.0.tar.gz 10 3
        cd /tmp && tar xf /tmp/luarocks-3.5.0.tar.gz
	    cd /tmp/luarocks-3.5.0
	    ./configure --with-lua-include=/www/server/total/lua515/include --with-lua-bin=/www/server/total/lua515/bin
	    make -I/www/server/total/lua515/bin
	    make install 
	    cd .. && rm -rf /tmp/luarocks-3.5.0.*
    fi

    if [ true ];then
        yum install -y sqlite-devel
        apt install -y libsqlite3-dev
        rm -rf /tmp/lsqlite3_fsl09y*
        wget -c -O /tmp/lsqlite3_fsl09y.zip http://download.bt.cn/btwaf_rule/test/btwaf/lsqlite3_fsl09y.zip  -T 10
        download_file /tmp/lsqlite3_fsl09y.zip http://download.bt.cn/btwaf_rule/test/btwaf/lsqlite3_fsl09y.zip 10 3
        cd /tmp && unzip /tmp/lsqlite3_fsl09y.zip && cd lsqlite3_fsl09y && make
        if [ ! -f '/tmp/lsqlite3_fsl09y/lsqlite3.so' ];then
            echo $tip9
            # wget -c -o /www/server/total/lsqlite3.so http://download.bt.cn/btwaf_rule/test/btwaf/lsqlite3.so -T 10
            download_file /www/server/total/lsqlite3.so http://download.bt.cn/btwaf_rule/test/btwaf/lsqlite3.so 10 3
        else
            echo $tip10
            \cp -a -r /tmp/lsqlite3_fsl09y/lsqlite3.so /www/server/total/lsqlite3.so
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

Install_sqlite3_for_apache()
{
    if [ -f '/usr/include/lua.h' ];then 
		include_path='/usr/include/'
    elif [ -f '/usr/include/lua5.1/lua.h' ];then
		include_path='/usr/include/lua5.1'
    elif [ -f '/usr/include/lua5.3/lua.h' ];then
		include_path='/usr/include/lua5.3'
	elif [ -f '/usr/local/include/luajit-2.0/lua.h' ];then 
		include_path='/usr/local/include/luajit-2.0/'
	elif [ -f '/usr/include/lua5.1/' ];then 
		include_path='/usr/include/lua5.1/'
	elif [ -f '/usr/local/include/luajit-2.1/' ];then 
		include_path='/usr/local/include/luajit-2.1/'
	else
		include_path=''
	fi

    if [ $(Get_lua_version) == "5.3" ] && [ -f '/usr/lib64/lua' ];then
        lua_bin='/usr/lib64'
	elif [ -f '/usr/bin/lua' ];then 
		lua_bin='/usr/bin/'
	elif [ -f '/usr/lib/lua' ];then 
		lua_bin='/usr/lib/'
	else
		lua_bin=`which lua | xargs dirname`
	fi
	
	if [ true ];then
		rm -rf /tmp/luarocks-3.5.0.*
		# wget -c -O /tmp/luarocks-3.5.0.tar.gz http://download.bt.cn/btwaf_rule/test/btwaf/luarocks-3.5.0.tar.gz  -T 10
		download_file /tmp/luarocks-3.5.0.tar.gz http://download.bt.cn/btwaf_rule/test/btwaf/luarocks-3.5.0.tar.gz 10 3

		cd /tmp && tar xvf /tmp/luarocks-3.5.0.tar.gz &&  cd /tmp/luarocks-3.5.0 && ./configure --with-lua-bin=$lua_bin --with-lua-include=$include_path
		make -I$include_path && make install && cd .. && rm -rf /tmp/luarocks-3.5.0.*
	fi

    if [ true ];then
        yum install -y sqlite-devel
        apt install -y libsqlite3-dev
        rm -rf /tmp/lsqlite3_fsl09y*
        # wget -c -O /tmp/lsqlite3_fsl09y.zip http://download.bt.cn/btwaf_rule/test/btwaf/lsqlite3_fsl09y.zip  -T 10
        download_file /tmp/lsqlite3_fsl09y.zip http://download.bt.cn/btwaf_rule/test/btwaf/lsqlite3_fsl09y.zip 10 3
        cd /tmp && unzip /tmp/lsqlite3_fsl09y.zip && cd lsqlite3_fsl09y && make
        if [ ! -f '/tmp/lsqlite3_fsl09y/lsqlite3.so' ];then
            echo $tip9
            # wget -c -o /www/server/total/lsqlite3.so http://download.bt.cn/btwaf_rule/test/btwaf/lsqlite3.so -T 10
            download_file /www/server/total/lsqlite3.so http://download.bt.cn/btwaf_rule/test/btwaf/lsqlite3.so 10 3
        else
            echo $tip10
            \cp -a -r /tmp/lsqlite3_fsl09y/lsqlite3.so /www/server/total/lsqlite3.so
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

Install_cjson()
{
    if [ -f /usr/local/lib/lua/5.1/cjson.so ];then
        is_jit_cjson=$(luajit -e "require 'cjson'" 2>&1|grep 'undefined symbol:luaL_setfuncs')
        if [ "$is_jit_cjson" != "" ];then
                rm -f /usr/local/lib/lua/5.1/cjson.so
        fi
    fi
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
            # wget -O lua-5.3-cjson.tar.gz $download_Url/src/lua-5.3-cjson.tar.gz -T 20
            download_file lua-5.3-cjson.tar.gz $download_Url/src/lua-5.3-cjson.tar.gz 20 3
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
        # wget -O lua-cjson-2.1.0.tar.gz $download_Url/install/src/lua-cjson-2.1.0.tar.gz -T 20
        download_file lua-cjson-2.1.0.tar.gz $download_Url/install/src/lua-cjson-2.1.0.tar.gz 20 3
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
    cd /tmp
    luarocks install lua-cjson
}

Install_socket()
{
    if [ ! -f /usr/local/lib/lua/5.1/socket/core.so ];then
        # wget -O luasocket-master.zip $download_Url/install/src/luasocket-master.zip -T 20
        download_file luasocket-master.zip $download_Url/install/src/luasocket-master.zip 20 3
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
                ln -sf /usr/local/lib/lua/5.1/socket /usr/lib/lua/5.1/socket
                ln -sf /usr/local/lib/lua/5.1/mime /usr/lib/lua/5.1/mime
        fi
        rm -rf /usr/share/lua/5.1/mime.lua /usr/share/lua/5.1/socket.lua /usr/share/lua/5.1/socket
        ln -sf /usr/local/share/lua/5.1/mime.lua /usr/share/lua/5.1/mime.lua
        ln -sf /usr/local/share/lua/5.1/socket.lua /usr/share/lua/5.1/socket.lua
        ln -sf /usr/local/share/lua/5.1/socket /usr/share/lua/5.1/socket
    fi
    cd /tmp
    luarocks install luasocket
}

Install_mod_lua_for_apache()
{
    if [ ! -f /www/server/apache/bin/httpd ];then
            return 0;
    fi

    if [ -f /www/server/apache/modules/mod_lua.so ];then
            return 0;
    fi
    cd /www/server/apache
    if [ ! -d /www/server/apache/src ];then
        # wget -O httpd-2.4.33.tar.gz $download_Url/src/httpd-2.4.33.tar.gz -T 20
        download_file httpd-2.4.33.tar.gz $download_Url/src/httpd-2.4.33.tar.gz 20 3
        tar xvf httpd-2.4.33.tar.gz
        rm -f httpd-2.4.33.tar.gz
        mv httpd-2.4.33 src
        cd /www/server/apache/src/srclib
        # wget -O apr-1.6.3.tar.gz $download_Url/src/apr-1.6.3.tar.gz
        download_file apr-1.6.3.tar.gz $download_Url/src/apr-1.6.3.tar.gz 10 3
        # wget -O apr-util-1.6.1.tar.gz $download_Url/src/apr-util-1.6.1.tar.gz
        download_file apr-util-1.6.1.tar.gz $download_Url/src/apr-util-1.6.1.tar.gz 10 3
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
        echo $tip8;
        exit 0;
    fi
}

# Install_ip_library()
# {
    # echo "更新最新IP库..."
    # mkdir $pluginPath/library/
    # wget -O $pluginPath/ip2Region.py  $download_Url/install/plugin/$remote_dir/ip2Region.py -T 10
    # download_file $pluginPath/ip2Region.py  $download_Url/install/plugin/$remote_dir/ip2Region.py 10 3

    # new_ip_db_md5="d59c1ba7e7a8a0cc3149037e0b3d849a"
    # current_ip_db_md5=`md5sum /www/server/panel/plugin/total/library/ip.db | awk '{print $1}'`
    # if [ $current_ip_db_md5 == $new_ip_db_md5 ]; then
    #     return 0
    # fi

    # wget -O $pluginPath/library/ip.db $download_Url/install/plugin/$remote_dir/ip.db -T 10
    # download_file $pluginPath/library/ip.db $download_Url/install/plugin/$remote_dir/ip.db 20 3
# }

Install_pdf_library()
{

    # if [ ! -f /usr/share/fonts/msyh.ttf ]; then
        # wget -O /usr/share/fonts/msyh.ttf  $download_Url/install/plugin/$remote_dir/msyh.ttf -T 10
        # download_file /usr/share/fonts/msyh.ttf  $download_Url/install/plugin/$remote_dir/msyh.ttf 20 3
    # fi
    
    if hash btpip 2>/dev/null; then
        btpip install pdfkit
    else
        pip install pdfkit
    fi

    if hash wkhtmltopdf 2>/dev/null; then
        echo "PDF module is installed."
        return 0
    fi

    v=`cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/'`
    if [ $v -eq 6 ]; then
        # wget -O $pluginPath/library/wkhtmltox-0.12.6-1.centos6.x86_64.rpm  $download_Url/install/plugin/$remote_dir/wkhtmltox-0.12.6-1.centos6.x86_64.rpm -T 10
        download_file $pluginPath/library/wkhtmltox-0.12.6-1.centos6.x86_64.rpm  $download_Url/install/plugin/$remote_dir/wkhtmltox-0.12.6-1.centos6.x86_64.rpm 10 3
        yum install -y $pluginPath/library/wkhtmltox-0.12.6-1.centos6.x86_64.rpm
    fi
    if [ $v -eq 7 ]; then
        # wget -O $pluginPath/library/wkhtmltox-0.12.6-1.centos7.x86_64.rpm $download_Url/install/plugin/$remote_dir/wkhtmltox-0.12.6-1.centos7.x86_64.rpm -T 10
        download_file $pluginPath/library/wkhtmltox-0.12.6-1.centos7.x86_64.rpm $download_Url/install/plugin/$remote_dir/wkhtmltox-0.12.6-1.centos7.x86_64.rpm 10 3
        yum install -y $pluginPath/library/wkhtmltox-0.12.6-1.centos7.x86_64.rpm
    fi
    Centos8Check=$(cat /etc/redhat-release | grep ' 8.' | grep -iE 'centos|Red Hat')
    if [ "${Centos8Check}" ];then
        # wget -O $pluginPath/library/wkhtmltox-0.12.6-1.centos8.x86_64.rpm $download_Url/install/plugin/$remote_dir/wkhtmltox-0.12.6-1.centos8.x86_64.rpm -T 10
        download_file $pluginPath/library/wkhtmltox-0.12.6-1.centos8.x86_64.rpm $download_Url/install/plugin/$remote_dir/wkhtmltox-0.12.6-1.centos8.x86_64.rpm 10 3
        yum install -y $pluginPath/library/wkhtmltox-0.12.6-1.centos8.x86_64.rpm
    fi

    if hash lsb_release 2>/dev/null; then
        if [ `lsb_release -i --short` == "Ubuntu" ]; then
            version=`lsb_release -r --short`
            if [ ${version:0:2} -eq 20 ];then
                echo $version
            fi

        fi
    fi

}

Install_nginx_environment()
{
    echo "Installing nginx environment..."
    Install_lua515
    Install_sqlite3_for_nginx
    Install_cjson
    # Install_ip_library
    # Install_pdf_library
}

Install_apache_environment()
{
    echo "Installing apache environment..."
    Install_mod_lua_for_apache
    Install_sqlite3_for_apache
    Install_cjson
    Install_socket
    # Install_ip_library
    # Install_pdf_library
}

Install_environment()
{
    if [ ! -f /usr/include/linux/limits.h ];then
        yum install kernel-headers -y
    fi
    if [ -f /www/server/apache/bin/httpd ];then
        Install_apache_environment    
    elif [ -f /www/server/nginx/sbin/nginx ];then
        Install_nginx_environment
    else
        echo "Please install nginx or apache first."
    fi
}

tip1="It is detected that cloud control is installed on the current panel, please use the old version of the monitoring report temporarily."
tip2="Start to install the old version of Monitoring Report v 3.7..."
tip3="Installing the plugin script file..."
tip4="Initializing data..."
tip5="Start the implementation of the plug-in patch..."
tip6="Data initialization completed."
tip7="The installation is complete."
tip8='Mod lua installation failed!'
tip9='Unsuccessful decompression'
tip10='Successfully decompressed'
tip11="Installation Failed！"

Install_total()
{
    mkdir -p $pluginPath
    mkdir -p $total_path
    if ! hash gcc 2>/dev/null;then
        yum install -y gcc
    fi

    if ! hash g++ 2>/dev/null;then
        yum install -y gcc+ gcc-c++
    fi

    Install_environment
    echo $tip3 > $install_tmp
    # wget -O $pluginPath/total_main.py $download_Url/install/plugin/$remote_dir/total_main.py -T 5
    download_file $pluginPath/total_main.py $download_Url/install/plugin/$remote_dir/total_main.py 5 3
    # wget -O $pluginPath/tsqlite.py $download_Url/install/plugin/$remote_dir/tsqlite.py -T 5
    download_file $pluginPath/tsqlite.py $download_Url/install/plugin/$remote_dir/tsqlite.py 5 3
    # wget -O $pluginPath/index.html $download_Url/install/plugin/$remote_dir/index.html -T 5
    download_file $pluginPath/index.html $download_Url/install/plugin/$remote_dir/index.html 5 3

    if [ ! -f $total_path/config.json ];then
        wget -O $total_path/config.json $download_Url/install/plugin/$remote_dir/config.json -T 5
        download_file $total_path/config.json $download_Url/install/plugin/$remote_dir/config.json 5 3
    fi
    if [ -f /www/server/panel/plugin/total/info.json ] && [ `cat /www/server/panel/plugin/total/info.json | grep 3.7` ];then
        # wget -O $total_path/config.json $download_Url/install/plugin/$remote_dir/config.json -T 5
        download_file $total_path/config.json $download_Url/install/plugin/$remote_dir/config.json 5 3
    fi

    # wget -O $pluginPath/info.json $download_Url/install/plugin/$remote_dir/info.json -T 5
    # wget -O $pluginPath/icon.png $download_Url/install/plugin/$remote_dir/icon.png -T 5
    download_file $pluginPath/icon.png $download_Url/install/plugin/$remote_dir/icon.png 5 3
    # wget -O $pluginPath/total_migrate.py $download_Url/install/plugin/$remote_dir/total_migrate.py -T 5
    download_file $pluginPath/total_migrate.py $download_Url/install/plugin/$remote_dir/total_migrate.py 5 3
    # wget -O $pluginPath/total_patch.py $download_Url/install/plugin/$remote_dir/total_patch.py -T 5
    download_file $pluginPath/total_patch.py $download_Url/install/plugin/$remote_dir/total_patch.py 5 3
    # wget -O $pluginPath/lua_maker.py $download_Url/install/plugin/$remote_dir/lua_maker.py -T 5
    download_file $pluginPath/lua_maker.py $download_Url/install/plugin/$remote_dir/lua_maker.py 5 3
    # wget -O $pluginPath/total_report.py $download_Url/install/plugin/$remote_dir/total_report.py -T 5
    download_file $pluginPath/total_report.py $download_Url/install/plugin/$remote_dir/total_report.py 5 3
    # wget -O $pluginPath/total_task.py $download_Url/install/plugin/$remote_dir/total_task.py -T 5
    download_file $pluginPath/total_task.py $download_Url/install/plugin/$remote_dir/total_task.py 5 3

    download_file $pluginPath/total_tools.py $download_Url/install/plugin/$remote_dir/total_tools.py 5 3

    if [ ! -f $pluginPath/task_config.json ]; then
        wget -O $pluginPath/task_config.json $download_Url/install/plugin/$remote_dir/task_config.json -t 5
        download_file $pluginPath/task_config.json $download_Url/install/plugin/$remote_dir/task_config.json 5 3
    fi

    # wget -O /www/server/panel/class/monitor.py $download_Url/install/plugin/$remote_dir/panelMonitor.py -T 5
    # download_file /www/server/panel/class/monitor.py $download_Url/install/plugin/$remote_dir/panelMonitor.py 5 3

    touch /www/server/total/debug.log
    chown www:www /www/server/total/debug.log
 
    if [ ! -f /www/server/panel/BTPanel/static/js/tools.min.js ];then
        # wget -O /www/server/panel/BTPanel/static/js/tools.min.js $download_Url/install/plugin/$remote_dir/tools.min.js -t 5
        download_file /www/server/panel/BTPanel/static/js/tools.min.js $download_Url/install/plugin/$remote_dir/tools.min.js 5 3
    fi

    mkdir $pluginPath/templates
    # wget -O $pluginPath/templates/baogao.html $download_Url/install/plugin/$remote_dir/templates/baogao.html -t 5
    download_file $pluginPath/templates/baogao_en.html $download_Url/install/plugin/$remote_dir/templates/baogao_en.html 5 3

    # wget -O $pluginPath/global_region.csv $download_Url/install/plugin/$remote_dir/global_region.csv -t 5
    # download_file $pluginPath/global_region.csv $download_Url/install/plugin/$remote_dir/global_region.csv 5 3

    if [ ! -f /www/server/panel/BTPanel/static/js/china.js ];then
        wget -O /www/server/panel/BTPanel/static/js/china.js $download_Url/install/plugin/$remote_dir/china.js -T 5
        download_file /www/server/panel/BTPanel/static/js/china.js $download_Url/install/plugin/$remote_dir/china.js 5 3
    fi
    # wget -O /www/server/total/total_httpd.conf $download_Url/install/plugin/$remote_dir/total_httpd.conf -T 5
    download_file /www/server/total/total_httpd.conf $download_Url/install/plugin/$remote_dir/total_httpd.conf 5 3
    # wget -O /www/server/total/total_nginx.conf $download_Url/install/plugin/$remote_dir/total_nginx.conf -T 5
    download_file /www/server/total/total_nginx.conf $download_Url/install/plugin/$remote_dir/total_nginx.conf 5 3
    if [ ! -f /www/server/total/closing ]; then
        \cp /www/server/total/total_httpd.conf /www/server/panel/vhost/apache/total.conf
        \cp /www/server/total/total_nginx.conf /www/server/panel/vhost/nginx/total.conf
    fi

    \cp -a -r /www/server/panel/plugin/total/icon.png /www/server/panel/BTPanel/static/img/soft_ico/ico-total.png
    # wget -O /tmp/total.zip $download_Url/install/plugin/$remote_dir/total.zip -T 5
    download_file /tmp/total.zip $download_Url/install/plugin/$remote_dir/total.zip 5 3
    mkdir -p /tmp/total
    unzip -o /tmp/total.zip -d /tmp/total > /dev/null
    \cp -a -r /tmp/total/total/* $total_path
    rm -rf /tmp/total/
    rm -rf /tmp/total.zip

    mkdir -p $pluginPath/language/English
    download_file $pluginPath/language/English/total.json $download_Url/install/plugin/$remote_dir/language/English/total.json 5 3

    mkdir -p $pluginPath/language/Simplified_Chinese
    download_file $pluginPath/language/Simplified_Chinese/total.json $download_Url/install/plugin/$remote_dir/language/Simplified_Chinese/total.json 5 3

    echo $tip4
    if hash btpip 2>/dev/null; then
        btpython $pluginPath/total_migrate.py
        echo $tip5
        btpython $pluginPath/total_patch.py
    else
        python $pluginPath/total_migrate.py
        echo $tip5
        python $pluginPath/total_patch.py
    fi
    echo $tip6

    chown -R www:www $total_path
    chmod -R 755 $total_path
    chmod +x $total_path/httpd_log.lua && chown -R root:root $total_path/httpd_log.lua
    chmod +x $total_path/nginx_log.lua && chown -R root:root $total_path/nginx_log.lua
    chmod +x $total_path/memcached.lua  && chown -R root:root $total_path/memcached.lua
    chmod +x $total_path/lsqlite3.so  && chown -R root:root $total_path/lsqlite3.so
    chmod +x $total_path/CRC32.lua  && chown -R root:root $total_path/CRC32.lua   
    waf=/www/server/panel/vhost/apache/btwaf.conf

    if [ ! -f $waf ];then
        echo "LoadModule lua_module modules/mod_lua.so" > $waf
    fi

    if [ -f /etc/init.d/httpd ];then
        /etc/init.d/httpd reload
    else
        /etc/init.d/nginx reload
        cat /www/server/nginx/logs/nginx.pid | xargs kill -HUP
    fi

    if [ ${#wrong_actions[*]} -gt 0 ];then
        echo $tip11
        for ((i=0;i<${#wrong_actions[@]};i++)) do
            echo ${wrong_actions[i]};
        done;
    else
        download_file $pluginPath/info.json $download_Url/install/plugin/$remote_dir/info.json 5 3
        echo $tip7
        echo $tip7 > $install_tmp
        echo > /www/server/panel/data/reload.pl
    fi
}

Uninstall_total()
{
    if [ -f /etc/init.d/httpd ];then
        if [ -f /www/server/total/uninstall.lua ];then
            lua /www/server/total/uninstall.lua
        fi
    fi

    if hash btpython 2>/dev/null; then
        btpython /www/server/panel/plugin/total/total_task.py remove
    else
        python /www/server/panel/plugin/total/total_task.py remove
    fi

    cd /tmp
    rm -rf /www/server/total
    rm -f /www/server/panel/vhost/apache/total.conf
    rm -f /www/server/panel/vhost/nginx/total.conf
    rm -rf $pluginPath

    if [ -f /etc/init.d/httpd ];then
        if [ ! -d /www/server/panel/plugin/btwaf_httpd ];then
            rm -f /www/server/panel/vhost/apache/btwaf.conf
        fi
        /etc/init.d/httpd reload
    else
        /etc/init.d/nginx reload
    fi
}

if [ "${1}" == 'install' ];then
    Install_total
elif  [ "${1}" == 'update' ];then
    Install_total
elif [ "${1}" == 'uninstall' ];then
    Uninstall_total
fi