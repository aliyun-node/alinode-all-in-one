#!/bin/sh

GIT=git

alinode_has() {
  type "$1" > /dev/null 2>&1
  return $?
}

alinode_temp_dir() {
  echo `pwd`"/tmp-"`echo $RANDOM`
  return $?
}

alinode_download() {
  if alinode_has "wget"; then
    ARGS=$(echo "$*" | sed -e 's/--progress-bar /--progress=bar /' \
                           -e 's/-L //' \
                           -e 's/-I //' \
                           -e 's/-s /-q /' \
                           -e 's/-o /-O /' \
                           -e 's/-C - /-c /')
    wget $ARGS
  else
    echo "请安装wget命令"
  fi
}

alinode_pre_install() {
  if [[ $- == *i* ]];
  then
    echo
  else
    echo
    echo '使用方法:'
    echo '  bash -i alinode_all.sh'
    exit
  fi

  if alinode_has $GIT; then
    echo
  elif alinode_has "wget"; then
    echo
  else
    echo >&2 "请安装命令 git, wget, unzip, 然后重新执行 bash -i alinode_all.sh "
    echo
    exit 1
  fi
}

#参数名称 默认值 参数说明
alinode_read_para() {
  echo $3  >&2
  echo 请输入 $1 [按回车接受默认值: $2] >&2

  read PARA
  if [ "$PARA" =  "" ]; then
    VAR=$2
  else
    VAR=$PARA
  fi
  echo "$1 设置为: $VAR"  >&2
  echo $VAR
}

alinode_read_array_para() {
  read args
  if [ -z "$args" ]; then
    echo []
  else
    para=""
    for a in $args
      do fa="\"$a\", "
        para="$para$fa"
    done
    para=`echo ${para::-2}`

    para=[$para]
    echo $para
  fi
}

alinode_install_tnvm() {
  echo '安装 tnvm...'
  echo
  echo "您的服务器来自阿里云ECS (y/n)?"
  read IS_ECS
  if [ "$IS_ECS" = y -o "$IS_ECS" = Y -o "$IS_ECS" = "" ]; then
    echo
  else
    echo '您可以试用阿里云ECS以便享受更快的安装速度哦......'
    echo
  fi

  if alinode_has $GIT; then
    TMP_TNVM_DIR=`alinode_temp_dir`
    git clone https://github.com/aliyun-node/tnvm.git $TMP_TNVM_DIR
    mv -f $TMP_TNVM_DIR/install.sh ./
    rm -rf $TMP_TNVM_DIR
  else
    TNVM_SOURCE="https://raw.githubusercontent.com/aliyun-node/tnvm/master/install.sh"
    alinode_download -s "$TNVM_SOURCE" -o "./install.sh"
  fi
  # bashrc的问题,需要先把这两个删掉
  sed -i '/exec bash/d' ./install.sh
  sed -i '/source "$NVM_PROFILE"/d' ./install.sh

  chmod a+x ./install.sh
  ./install.sh

  source ~/.bashrc
  rm ./install.sh
}

alinode_install_alinode() {
  PACKAGE=`alinode_read_para '需要安装的二进制包 可选项: alinode/node/iojs' alinode ""`
  echo
  echo '您的选择:' $PACKAGE
  echo '请选择具体版本:'
  CHOICES=`tnvm lookup|awk '{print $6 "--基于node-" $9}'`
  echo
  for CHOICE in $CHOICES
    do
      echo $CHOICE
      DEFAULT_PACKAGE=$CHOICE
  done

  # 去掉颜色信息
  DEFAULT_PACKAGE=`echo $DEFAULT_PACKAGE|sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"|awk -F "--" '{print $1}'`

  INSTALL_PACKAGE=`alinode_read_para "$PACKAGE 具体版本(例如alinode-v1.0.0)" $DEFAULT_PACKAGE "" `
  tnvm install $INSTALL_PACKAGE
  tnvm use $INSTALL_PACKAGE

  if [ "$PACKAGE" = "alinode" ]; then
    echo alinode 内部版本: `node -p "process.alinode"` 对应的node版本: `node -v`
  else
    echo $PACKAGE 版本: `node -v`
  fi
}

alinode_install_cnpm() {
  if ! alinode_has "cnpm"; then
    echo
    echo "安装 cnpm以实现npm加速..."
    npm install -g cnpm --registry=http://registry.npm.taobao.org
  fi
}

alinode_install_agenthub() {
  echo
  echo '安装 agenthub...'
  if alinode_has "cnpm"; then
    cnpm install @alicloud/agenthub -g
  else
    npm install @alicloud/agenthub -g
  fi
}

config_hint_id_token() {
  echo '您可以通过下述方式获取您的应用Id和应用Token:'
  echo
  echo '如果是第一次使用'
  echo '打开 https://node.console.aliyun.com/'
  echo '通过阿里云账号登陆'
  echo '点击用户名'
  echo '添加应用->输入您的应用名->下一步'
  echo '获得 应用Id 和 应用Token'
  echo
  echo '如果您已有应用Id和Token'
  echo '登陆后点击应用名->右侧应用设置'
  echo '获得 应用Id 和 应用Token'
}

config_hint_logdir() {
  echo '设置alinode log目录...'
  echo
  echo -e '\e[31m注意: ***必须与启动应用时的环境变量NODE_LOG_DIR相同***\e[0m'
  echo -e '\e[31m      ***若不设置NODE_LOG_DIR,那么使用 /tmp/ 目录  ***\e[0m'
}

config_hint_error_log() {
  echo '请输入error_log目录'
  echo -e '\e[31merror_log是您的应用自己输出的日志，带有stack信息\e[0m'
  echo -e '\e[31m格式: /path/to/your/error_log/error.#YYYY-#MM-#DD.log\e[0m'
  echo -e '\e[31m多于1个error_log，以空格分隔\e[0m'
  echo -e '\e[31m不要此项功能，回车跳过\e[0m'
}

config_hint_packages() {
  echo '请输入dependency目录'
  echo -e '\e[31mdependency是您的应用依赖包信息\e[0m'
  echo -e '\e[31m格式: /path/to/your/error_log/yourdep.json\e[0m'
  echo -e '\e[31m多于1个，以空格分隔\e[0m'
  echo -e '\e[31m不要此项功能，回车跳过\e[0m'
}

alinode_configure_agenthub() {
  echo
  echo '配置agenthub...'
  echo
  config_hint_id_token
  echo
  echo '请输入应用ID'
  read APP_ID
  echo '您的应用Id: ' $APP_ID
  echo
  echo '请输入应用Token'
  read APP_TOKEN
  echo '您的应用Token: ' $APP_TOKEN
  echo

  config_hint_logdir
  LOG_DIR=`alinode_read_para "alinode log 目录" "/tmp/" ""`

  config_hint_error_log
  err=`alinode_read_array_para`

  config_hint_packages
  dep=`alinode_read_array_para`

  DEFAULT_CFG_DIR=`pwd`
  CFG_DIR=`alinode_read_para "配置文件目录" $DEFAULT_CFG_DIR  ""`
  CFG_PATH=$CFG_DIR'/yourconfig.json'
  touch $CFG_PATH
  > $CFG_PATH

  echo   { >> $CFG_PATH
  echo   "  "\"server\":            \"agentserver.node.aliyun.com:8080\", >> $CFG_PATH
  echo   "  "\"appid\":             \"$APP_ID\", >> $CFG_PATH
  echo   "  "\"secret\":            \"$APP_TOKEN\", >> $CFG_PATH
  echo   "  "\"logdir\":            \"$LOG_DIR\", >> $CFG_PATH
  echo   "  "\"reconnectDelay\":    10, >> $CFG_PATH
  echo   "  "\"heartbeatInterval\": 60, >> $CFG_PATH
  echo   "  "\"reportInterval\":    60, >> $CFG_PATH
  echo   "  "\"error_log\":         $err, >>$CFG_PATH
  echo   "  "\"packages\":          $dep >>$CFG_PATH
  echo   } >> $CFG_PATH

  echo
  echo 您的配置如下,您可以手工修改$CFG_PATH来改变配置
  cat $CFG_PATH
}

alinode_post_install() {
  echo
  echo '通过下面命令启动agenthub, 快乐享受alinode服务':
  echo
  echo '    nohup agenthub' $CFG_PATH '&'
  echo
  exec bash
}


alinode_pre_install
alinode_install_tnvm
alinode_install_alinode
alinode_install_cnpm
alinode_install_agenthub
alinode_configure_agenthub
alinode_post_install
