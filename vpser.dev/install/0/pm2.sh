#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
export HOME=/root
install_tmp='/tmp/bt_install.pl'
public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
	wget -O $public_file http://vpser.dev/install/public.sh -T 5;
fi

. $public_file

download_Url=$NODE_URL
mirror_Url="https://npm.taobao.org/mirrors/node"

mirrorCheck=$(curl --connect-timeout 5 --head -s -o /dev/null -w "%{http_code} %{time_total}" ${mirror_Url})
mirrorStatus=$(echo $mirrorCheck|awk '{print $1}')
mirrorSpeed=$(echo $mirrorCheck|awk '{print $2}'|cut -d '.' -f 1)
if [ "${mirrorStatus}" == "200" ] && [ "${mirrorSpeed}" -le "3" ];then
  taobaoMirror="true"
  export NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node
fi


Install_nvm()
{ # this ensures the entire script is downloaded #

nvm_has() {
  type "$1" > /dev/null 2>&1
}

nvm_install_dir() {
  printf %s "${NVM_DIR:-"/www/server/nvm"}"
}

nvm_latest_version() {
  echo "v0.33.4"
}

nvm_profile_is_bash_or_zsh() {
  local TEST_PROFILE
  TEST_PROFILE="${1-}"
  case "${TEST_PROFILE-}" in
    *"/.bashrc" | *"/.bash_profile" | *"/.zshrc")
      return
    ;;
    *)
      return 1
    ;;
  esac
}

#
# Outputs the location to NVM depending on:
# * The availability of $NVM_SOURCE
# * The method used ("script" or "git" in the script, defaults to "git")
# NVM_SOURCE always takes precedence unless the method is "script-nvm-exec"
#
nvm_source() {
  local NVM_METHOD
  NVM_METHOD="$1"
  local NVM_SOURCE_URL
  NVM_SOURCE_URL="$NVM_SOURCE"
  if [ "_$NVM_METHOD" = "_script-nvm-exec" ]; then
    NVM_SOURCE_URL="${download_Url}/src/nvm/nvm-exec"
  elif [ "_$NVM_METHOD" = "_script-nvm-bash-completion" ]; then
    NVM_SOURCE_URL="${download_Url}/src/nvm/bash_completion"
  elif [ -z "$NVM_SOURCE_URL" ]; then
    if [ "_$NVM_METHOD" = "_script" ]; then
      NVM_SOURCE_URL="${download_Url}/src/nvm/nvm.sh"
    elif [ "_$NVM_METHOD" = "_git" ] || [ -z "$NVM_METHOD" ]; then
      NVM_SOURCE_URL="https://github.com/creationix/nvm.git"
    else
      echo >&2 "Unexpected value \"$NVM_METHOD\" for \$NVM_METHOD"
      return 1
    fi
  fi
  echo "$NVM_SOURCE_URL"
}

#
# Node.js version to install
#
nvm_node_version() {
  echo "$NODE_VERSION"
}

nvm_download() {
  if nvm_has "curl"; then
    curl --compressed -q "$@"
  elif nvm_has "wget"; then
    # Emulate curl with wget
    ARGS=$(echo "$*" | command sed -e 's/--progress-bar /--progress=bar /' \
                           -e 's/-L //' \
                           -e 's/--compressed //' \
                           -e 's/-I /--server-response /' \
                           -e 's/-s /-q /' \
                           -e 's/-o /-O /' \
                           -e 's/-C - /-c /')
    # shellcheck disable=SC2086
    eval wget $ARGS
  fi
}

install_nvm_from_git() {
  local INSTALL_DIR
  INSTALL_DIR="$(nvm_install_dir)"

  if [ -d "$INSTALL_DIR/.git" ]; then
    echo "=> nvm is already installed in $INSTALL_DIR, trying to update using git"
    command printf "\r=> "
    command git --git-dir="$INSTALL_DIR "/.git --work-tree="$INSTALL_DIR" fetch origin tag "$(nvm_latest_version)" --depth=1 2> /dev/null || {
      echo >&2 "Failed to update nvm, run 'git fetch' in $INSTALL_DIR yourself."
      exit 1
    }
  else
    rm -rf /www/server/nvm
    wget -O /www/server/nvm-0.37.2.tar.gz ${download_Url}/src/nvm-0.37.2.tar.gz
    tar -xvf /www/server/nvm-0.37.2.tar.gz
    mv nvm-0.37.2 /www/server/nvm
    rm -f /www/server/nvm-0.37.2.tar.gz
  fi
  command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" checkout -f --quiet "$(nvm_latest_version)"
  if [ ! -z "$(command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" show-ref refs/heads/master)" ]; then
    if command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet 2>/dev/null; then
      command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet -D master >/dev/null 2>&1
    else
      echo >&2 "Your version of git is out of date. Please update it!"
      command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch -D master >/dev/null 2>&1
    fi
  fi

  echo "=> Compressing and cleaning up git repository"
  if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" reflog expire --expire=now --all; then
    echo >&2 "Your version of git is out of date. Please update it!"
  fi
  if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" gc --auto --aggressive --prune=now ; then
    echo >&2 "Your version of git is out of date. Please update it!"
  fi
  return
}

#
# Automatically install Node.js
#
nvm_install_node() {
  local NODE_VERSION
  NODE_VERSION="$(nvm_node_version)"

  if [ -z "$NODE_VERSION" ]; then
    return 0
  fi

  echo "=> Installing Node.js version $NODE_VERSION"
  nvm install "$NODE_VERSION"
  local CURRENT_NVM_NODE

  CURRENT_NVM_NODE="$(nvm_version current)"
  if [ "$(nvm_version "$NODE_VERSION")" == "$CURRENT_NVM_NODE" ]; then
    echo "=> Node.js version $NODE_VERSION has been successfully installed"
  else
    echo >&2 "Failed to install Node.js $NODE_VERSION"
  fi
}

install_nvm_as_script() {
  local INSTALL_DIR
  INSTALL_DIR="$(nvm_install_dir)"
  local NVM_SOURCE_LOCAL
  NVM_SOURCE_LOCAL="$(nvm_source script)"
  local NVM_EXEC_SOURCE
  NVM_EXEC_SOURCE="$(nvm_source script-nvm-exec)"
  local NVM_BASH_COMPLETION_SOURCE
  NVM_BASH_COMPLETION_SOURCE="$(nvm_source script-nvm-bash-completion)"

  # Downloading to $INSTALL_DIR
  mkdir -p "$INSTALL_DIR"
  if [ -f "$INSTALL_DIR/nvm.sh" ]; then
    echo "=> nvm is already installed in $INSTALL_DIR, trying to update the script"
  else
    echo "=> Downloading nvm as script to '$INSTALL_DIR'"
  fi
  nvm_download -s "$NVM_SOURCE_LOCAL" -o "$INSTALL_DIR/nvm.sh" || {
    echo >&2 "Failed to download '$NVM_SOURCE_LOCAL'"
    return 1
  } &
  nvm_download -s "$NVM_EXEC_SOURCE" -o "$INSTALL_DIR/nvm-exec" || {
    echo >&2 "Failed to download '$NVM_EXEC_SOURCE'"
    return 2
  } &
  nvm_download -s "$NVM_BASH_COMPLETION_SOURCE" -o "$INSTALL_DIR/bash_completion" || {
    echo >&2 "Failed to download '$NVM_BASH_COMPLETION_SOURCE'"
    return 2
  } &
  for job in $(jobs -p | sort)
  do
    wait "$job" || return $?
  done
  chmod a+x "$INSTALL_DIR/nvm-exec" || {
    echo >&2 "Failed to mark '$INSTALL_DIR/nvm-exec' as executable"
    return 3
  }
}

nvm_try_profile() {
  if [ -z "${1-}" ] || [ ! -f "${1}" ]; then
    return 1
  fi
  echo "${1}"
}

#
# Detect profile file if not specified as environment variable
# (eg: PROFILE=~/.myprofile)
# The echo'ed path is guaranteed to be an existing file
# Otherwise, an empty string is returned
#
nvm_detect_profile() {
  if [ -n "${PROFILE}" ] && [ -f "${PROFILE}" ]; then
    echo "${PROFILE}"
    return
  fi

  local DETECTED_PROFILE
  DETECTED_PROFILE=''
  local SHELLTYPE
  SHELLTYPE="$(basename "/$SHELL")"

  if [ "$SHELLTYPE" = "bash" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      DETECTED_PROFILE="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      DETECTED_PROFILE="$HOME/.bash_profile"
    fi
  elif [ "$SHELLTYPE" = "zsh" ]; then
    DETECTED_PROFILE="$HOME/.zshrc"
  fi

  if [ -z "$DETECTED_PROFILE" ]; then
    for EACH_PROFILE in ".profile" ".bashrc" ".bash_profile" ".zshrc"
    do
      if DETECTED_PROFILE="$(nvm_try_profile "${HOME}/${EACH_PROFILE}")"; then
        break
      fi
    done
  fi

  if [ ! -z "$DETECTED_PROFILE" ]; then
    echo "$DETECTED_PROFILE"
  fi
}

#
# Check whether the user has any globally-installed npm modules in their system
# Node, and warn them if so.
#
nvm_check_global_modules() {
  command -v npm >/dev/null 2>&1 || return 0

  local NPM_VERSION
  NPM_VERSION="$(npm --version)"
  NPM_VERSION="${NPM_VERSION:--1}"
  [ "${NPM_VERSION%%[!-0-9]*}" -gt 0 ] || return 0

  local NPM_GLOBAL_MODULES
  NPM_GLOBAL_MODULES="$(
    npm list -g --depth=0 |
    command sed -e '/ npm@/d' -e '/ (empty)$/d'
  )"

  local MODULE_COUNT
  MODULE_COUNT="$(
    command printf %s\\n "$NPM_GLOBAL_MODULES" |
    command sed -ne '1!p' |                     # Remove the first line
    wc -l | tr -d ' '                           # Count entries
  )"

  if [ "${MODULE_COUNT}" != '0' ]; then
    # shellcheck disable=SC2016
    echo '=> You currently have modules installed globally with `npm`. These will no'
    # shellcheck disable=SC2016
    echo '=> longer be linked to the active version of Node when you install a new node'
    # shellcheck disable=SC2016
    echo '=> with `nvm`; and they may (depending on how you construct your `$PATH`)'
    # shellcheck disable=SC2016
    echo '=> override the binaries of modules installed with `nvm`:'
    echo

    command printf %s\\n "$NPM_GLOBAL_MODULES"
    echo '=> If you wish to uninstall them at a later point (or re-install them under your'
    # shellcheck disable=SC2016
    echo '=> `nvm` Nodes), you can remove them from the system Node as follows:'
    echo
    echo '     $ nvm use system'
    echo '     $ npm uninstall -g a_module'
    echo
  fi
}

nvm_do_install() {
  if [ -z "${METHOD}" ]; then
    # Autodetect install method
    if nvm_has git; then
      install_nvm_from_git
    elif nvm_has nvm_download; then
      install_nvm_as_script
    else
      echo >&2 'You need git, curl, or wget to install nvm'
      exit 1
    fi
  elif [ "${METHOD}" = 'git' ]; then
    if ! nvm_has git; then
      echo >&2 "You need git to install nvm"
      exit 1
    fi
    install_nvm_from_git
  elif [ "${METHOD}" = 'script' ]; then
    if ! nvm_has nvm_download; then
      echo >&2 "You need curl or wget to install nvm"
      exit 1
    fi
    install_nvm_as_script
  fi

  echo

  local NVM_PROFILE
  NVM_PROFILE="$(nvm_detect_profile)"
  local PROFILE_INSTALL_DIR
  PROFILE_INSTALL_DIR="$(nvm_install_dir| sed "s:^$HOME:\$HOME:")"

  SOURCE_STR="\nexport NVM_DIR=\"${PROFILE_INSTALL_DIR}\"\n[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"  # This loads nvm\n"
  COMPLETION_STR="[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"  # This loads nvm bash_completion\n"
  BASH_OR_ZSH=false

  if [ -z "${NVM_PROFILE-}" ] ; then
    echo "=> Profile not found. Tried ${NVM_PROFILE} (as defined in \$PROFILE), ~/.bashrc, ~/.bash_profile, ~/.zshrc, and ~/.profile."
    echo "=> Create one of them and run this script again"
    echo "=> Create it (touch ${NVM_PROFILE}) and run this script again"
    echo "   OR"
    echo "=> Append the following lines to the correct file yourself:"
    command printf "${SOURCE_STR}"
  else
    if nvm_profile_is_bash_or_zsh "${NVM_PROFILE-}"; then
      BASH_OR_ZSH=true
    fi
    if ! command grep -qc '/nvm.sh' "$NVM_PROFILE"; then
      echo "=> Appending nvm source string to $NVM_PROFILE"
      command printf "${SOURCE_STR}" >> "$NVM_PROFILE"
    else
      echo "=> nvm source string already in ${NVM_PROFILE}"
    fi
    # shellcheck disable=SC2016
    if ${BASH_OR_ZSH} && ! command grep -qc '$NVM_DIR/bash_completion' "$NVM_PROFILE"; then
      echo "=> Appending bash_completion source string to $NVM_PROFILE"
      command printf "$COMPLETION_STR" >> "$NVM_PROFILE"
    else
      echo "=> bash_completion source string already in ${NVM_PROFILE}"
    fi
  fi
  if ${BASH_OR_ZSH} && [ -z "${NVM_PROFILE-}" ] ; then
    echo "=> Please also append the following lines to the if you are using bash/zsh shell:"
    command printf "${COMPLETION_STR}"
  fi

  # Source nvm
  # shellcheck source=/dev/null
  \. "$(nvm_install_dir)/nvm.sh"

  nvm_check_global_modules

  nvm_install_node

  nvm_reset

  echo "=> Close and reopen your terminal to start using nvm or run the following to use it now:"
  command printf "${SOURCE_STR}"
  if ${BASH_OR_ZSH} ; then
    command printf "${COMPLETION_STR}"
  fi
}

#
# Unsets the various functions defined
# during the execution of the install script
#
nvm_reset() {
  unset -f nvm_has nvm_install_dir nvm_latest_version nvm_profile_is_bash_or_zsh \
    nvm_source nvm_node_version nvm_download install_nvm_from_git nvm_install_node \
    install_nvm_as_script nvm_try_profile nvm_detect_profile nvm_check_global_modules \
    nvm_do_install nvm_reset
}

[ "_$NVM_ENV" = "_testing" ] || nvm_do_install

} # this ensures the entire script is downloaded #

Uninstall_nvm(){
	source /www/server/nvm/nvm.sh
	pm2 stop all
	rm -rf /www/server/nvm
	sed -i "/NVM/d" /root/.bash_profile
	sed -i "/NVM/d" /root/.bashrc
	rm -rf /www/server/panel/plugin/pm2
	rm -rf /root/.pm2
	rm -rf /root/.npm
	rm -rf /root/.npmrc
}

My_Install(){
	if [ ! -f /www/server/nvm/nvm-exec ];then
		Install_nvm
		. ~/.bash_profile
		. ~/.bashrc
	
		source /www/server/nvm/nvm.sh
		nvm install --lts
		oldreg=`npm get registry`
    if [ "${taobaoMirror}" == "true" ];then
		  npm config set registry http://registry.npm.taobao.org/
		fi
    npm install -g pm2
		npm config set registry $oldreg
	fi
	echo '正在安装脚本文件...' > $install_tmp
	mkdir -p /www/server/panel/plugin/pm2
	grep "English" /www/server/panel/config/config.json
	if [ "$?" -ne 0 ];then
	    wget -O /www/server/panel/plugin/pm2/pm2_main.py $download_Url/install/plugin/pm2/pm2_main.py -T 5
        wget -O /www/server/panel/plugin/pm2/index.html $download_Url/install/plugin/pm2/index.html -T 5
		wget -O /www/server/panel/plugin/pm2/info.json $download_Url/install/plugin/pm2/info.json -T 5
		wget -O /www/server/panel/plugin/pm2/icon.png $download_Url/install/plugin/pm2/icon.png -T 5
		wget -O /www/server/panel/static/img/soft_ico/ico-pm2.png $download_Url/install/plugin/pm2/icon.png -T 5
	else
		wget -O /www/server/panel/plugin/pm2/pm2_main.py $download_Url/install/plugin/pm2_en/pm2_main.py -T 5
		wget -O /www/server/panel/plugin/pm2/index.html $download_Url/install/plugin/pm2_en/index.html -T 5
		wget -O /www/server/panel/plugin/pm2/info.json $download_Url/install/plugin/pm2_en/info.json -T 5
		wget -O /www/server/panel/plugin/pm2/icon.png $download_Url/install/plugin/pm2_en/icon.png -T 5
		wget -O /www/server/panel/static/img/soft_ico/ico-pm2.png $download_Url/install/plugin/pm2_en/icon.png -T 5
	fi
	echo '安装完成' > $install_tmp
}


action=$1
if [ "${1}" == 'install' ];then
	My_Install
elif [ "$1" == 'update' ];then
	My_Install
else
	Uninstall_nvm
fi



