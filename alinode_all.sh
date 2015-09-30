#!/bin/sh

if [[ $- == *i* ]];
then
  echo ''
else
  echo 'Usage:'
  echo '  bash -i alinode_all.sh'
  exit
fi

#参数名称 默认值 参数说明
_read_user_enter() {
  echo $3  >&2
  echo 请输入 $1 [按回车接受默认值: $2] >&2

  read USR_ENTER
  if [ "$USR_ENTER" =  "" ]; then
    VAR=$2
  else
    VAR=$USR_ENTER
  fi
  echo "$1 设置为: $VAR"  >&2
  echo $VAR
}

echo '安装 tnvm...'
echo ''
echo "您的服务器来自阿里云ECS (y/n)?"
read IS_ECS
if [ "$IS_ECS" = y -o "$IS_ECS" = Y -o "$IS_ECS" = '' ]; then
  METHOD=script wget --no-check-certificate https://raw.githubusercontent.com/aliyun-node/tnvm/master/install.sh
else
  echo '您可以试用阿里云ECS以便享受更快的安装速度哦......'
  echo ''
  wget  https://raw.githubusercontent.com/aliyun-node/tnvm/master/install.sh --no-check-certificate
fi

# bashrc的问题,需要先把这两个删掉
sed -i '/exec bash/d' ./install.sh
sed -i '/source "$NVM_PROFILE"/d' ./install.sh

chmod a+x ./install.sh
./install.sh

source ~/.bashrc

PACKAGE=`_read_user_enter '需要安装的二进制包 可选项: alinode/node/iojs' alinode ''`
echo ''

echo '您的选择:' $PACKAGE

echo '请选择具体版本:'
CHOICES=`tnvm ls-remote $PACKAGE`
for CHOICE in $CHOICES
do
  echo $CHOICE
  DEFAULT_PACKAGE=$CHOICE
done

# 去掉颜色信息
DEFAULT_PACKAGE=`echo $DEFAULT_PACKAGE|sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"`

INSTALL_PACKAGE=`_read_user_enter "$PACKAGE 具体版本" $DEFAULT_PACKAGE "" `
tnvm install $INSTALL_PACKAGE
tnvm use $INSTALL_PACKAGE

if [ "$PACKAGE" = "alinode" ]; then
  echo alinode 版本: `node -p "process.alinode"` 对应的node版本: `node -v`
else
  echo $PACKAGE 版本: `node -v`
fi

echo ''
echo '安装 agentx...'
npm -g install agentx

echo ''
echo '安装 命令集...'
DEFAULT_COMMAND_DIR=`echo ~/`.alinodescripts
COMMAND_DIR=`_read_user_enter "命令集目录"  $DEFAULT_COMMAND_DIR  ""`
mkdir -p $COMMAND_DIR

if [ -d "$DEFAULT_COMMAND_DIR/.git" ]; then
  cd $DEFAULT_COMMAND_DIR && (command git pull 2> /dev/null || {
  echo '   请在'$DEFAULT_COMMAND_DIR'目录下运行命令: git pull 更新到最新命令集'
  })
  cd - 2> /dev/null
else
  echo 'git clone https://github.com/aliyun-node/commands.git' $COMMAND_DIR
  git clone https://github.com/aliyun-node/commands.git $COMMAND_DIR
fi

echo ''
echo '配置agentx...'
echo ''
echo '您可以通过下述方式获取您的应用Id和应用Token:'
echo ''
echo '如果是第一次使用'
echo '打开 http://alinode.aliyun.com/'
echo '通过阿里云账号登陆'
echo '点击用户名'
echo '添加应用->输入您的应用名->下一步'
echo '获得 应用Id 和 应用Token'
echo ''
echo '如果您已有应用Id和Token'
echo '登陆后点击应用名->右侧应用设置'
echo '获得 应用Id 和 应用Token'
echo ''
echo '请输入应用ID'
read APP_ID
echo '您的应用Id: ' $APP_ID
echo ''
echo '请输入应用Token'
read APP_TOKEN
echo '您的应用Token: ' $APP_TOKEN
echo ''

echo '设置alinode log目录...'
echo ''
echo '注意: ***必须与启动应用时的环境变量NODE_LOG_DIR相同***'
LOG_DIR=`_read_user_enter "alinode log 目录" "/tmp/" ""`

DEFAULT_CFG_DIR=`pwd`
CFG_DIR=`_read_user_enter "配置文件目录" $DEFAULT_CFG_DIR  ""`
CFG_PATH=$CFG_DIR'/yourconfig.json'
touch $CFG_PATH
> $CFG_PATH

echo   { >> $CFG_PATH
echo   "  "\"server\":            \"120.55.151.247\", >> $CFG_PATH
echo   "  "\"appid\":             \"$APP_ID\", >> $CFG_PATH
echo   "  "\"secret\":            \"$APP_TOKEN\", >> $CFG_PATH
echo   "  "\"cmddir\":            \"$COMMAND_DIR\", >> $CFG_PATH
echo   "  "\"logdir\":            \"$LOG_DIR\", >> $CFG_PATH
echo   "  "\"reconnectDelay\":    10, >> $CFG_PATH
echo   "  "\"heartbeatInterval\": 60, >> $CFG_PATH
echo   "  "\"reportInterval\":    60 >> $CFG_PATH
echo   } >> $CFG_PATH

echo
echo 您的配置如下,您可以手工修改$CFG_PATH来改变配置
cat $CFG_PATH

echo ''
echo '通过下面命令启动agentx, 快乐享受alinode服务':
echo ''
echo '    nohup agentx' $CFG_PATH '&'
echo ''

exec bash
