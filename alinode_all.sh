#!/bin/sh

if [[ $- == *i* ]];
then
  alias echo='echo -e'
else
  echo 'Usage:'
  echo '  bash -i alinode_all.sh'
  exit
fi

#参数名称 默认值 参数说明
_read_user_enter() {
  echo $3  >&2
  echo Please enter $1 [Press enter to accept default: $2] >&2

  read usrVar
  if [ "$usrVar" =  "" ]; then
    var=$2
  else
    var=$usrVar
  fi
  echo "$1 is set as: $var"  >&2
  echo $var
}

echo '\nInstalling tnvm...'
echo "\nAre you using ECS from aliyun (y/n)?"
read is_aliyun_ecs

if [ "$is_aliyun_ecs" = y -o "$is_aliyun_ecs" = Y -o "$is_aliyun_ecs" = '' ]
then
  METHOD=script wget --no-check-certificate https://raw.githubusercontent.com/aliyun-node/tnvm/master/install.sh
else
  echo 'You may try aliyun ECS to benefit from ......'
  wget  https://raw.githubusercontent.com/aliyun-node/tnvm/master/install.sh --no-check-certificate
fi

# bashrc的问题,需要先把这两个删掉
sed -i '/exec bash/d' ./install.sh
sed -i '/source "$NVM_PROFILE"/d' ./install.sh

chmod a+x ./install.sh
./install.sh

source ~/.bashrc

install_package=`_read_user_enter 'package you want to install' alinode 'select from: alinode/node/iojs'`
echo '\nplease select from the following list for: ' $install_package
choices=`tnvm ls-remote $install_package`
for choice in $choices
do
  echo $choice
  default_choice=$choice
done

# 去掉颜色信息
default_choice=`echo $default_choice|sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"`

to_install=`_read_user_enter "$install_package version" $default_choice "enter $install_package with version" `
tnvm install $to_install
tnvm use $to_install

if [ "$install_package" = "alinode" ];
  then
  echo alinode version: `node -p "process.alinode"` and corresponding node version: `node -v`
else
  echo $install_package version `node -v`
fi

echo '\nInstalling agentx...'
npm -g install agentx

echo '\nInstall command scripts...'
default_cmd_dir=`echo ~/`.alinodescripts
command_dir=`_read_user_enter "scripts directory"  $default_cmd_dir  "provide directory for scripts"`
mkdir -p $command_dir
git clone https://github.com/aliyun-node/commands.git $command_dir

echo 'now config your agentx\n'
echo '您可以通过下述方式获取您的应用Id和应用Token:\n'
echo '如果是第一次使用'
echo '打开 http://alinode.aliyun.com/'
echo '通过阿里云账号登陆'
echo '点击用户名'
echo '添加应用->输入您的应用名->下一步'
echo '获得 应用Id 和 应用Token\n'
echo '如果您已有应用id和Token'
echo '登陆后点击应用名->右侧应用设置'
echo '获得 应用Id 和 应用Token\n'
echo '请输入应用ID'
read appId
echo '您的应用Id: ' $appId '\n'
echo '请输入应用Token'
read appToken
echo '您的应用Token: ' $appToken '\n'

log_dir=`_read_user_enter "alinode log directory" "/tmp/" "输入alinode log文件夹\n***必须与启动应用时的环境变量NODE_LOG_DIR相同***"`

default_config_dir=`pwd`
config_dir=`_read_user_enter "config.json directory" $default_config_dir "输入配置文件夹"`
config=$config_dir'/yourconfig.json'
echo 'ddddddd' $config
touch $config
> $config

echo   { >> $config
echo   \"server\":            \"127.0.0.1:8080\", >> $config
echo   \"appid\":             \"$appId\", >> $config
echo   \"secret\":            \"$appToken\", >> $config
echo   \"cmddir\":            \"$command_dir\", >> $config
echo   \"logdir\":            \"$log_dir\", >> $config
echo   \"reconnectDelay\":    10, >> $config
echo   \"heartbeatInterval\": 60, >> $config
echo   \"reportInterval\":    60 >> $config
echo   } >> $config

echo
echo 您的配置如下,您可以手工修改$config来改变配置
cat $config

echo '\nCongratulations~~~\n'
echo start agentx via: nohup agentx $config &
echo

exec bash
