
## alinode-all-in-one
---
one-script installs Node.js Performance Platform solution

## Installation

Download script to current directory:

```
wget -q https://raw.githubusercontent.com/aliyun-node/alinode-all-in-one/master/alinode_all.sh
```

如果遇到 ssl 证书问题， 尝试wget加上选项 `--no-check-certificate`

## Usage

```
bash -i alinode_all.sh
```

This script will help you install all needed step by step.

1. install tnvm.
2. install alinode, node or iojs with tnvm. You may specify a certain version during installation.
3. install agenthub, this may take a while.
4. create a configuration to start agenthub. appid and app token must be provided.

### More
As the network performance and different authority configuration, this script may not work as expected.

Then you may install manually as following:

1. install tnvm
```sh
$ wget -qO- https://raw.githubusercontent.com/aliyun-node/tnvm/master/install.sh | bash
```
2. install alinode with tnvm
```sh
$ tnvm install alinode-v4.1.0
```
3. install agenthub
```sh
npm install @alicloud/agenthub -g
```
4. create a configuration(`/path/to/config/yourconfig.json`) with the following format:

```json
{
  "server": "wss://agentserver.node.aliyun.com",
  "appid": "your_app_id",
  "secret": "your_app_token",
  "logdir": "/nodelog/directory",
  "reconnectDelay": 10,
  "heartbeatInterval": 60,
  "reportInterval": 60
}
```

6. start agentx: nohup agentx /path/to/config/yourconfig.json &

### Note
- You may modify your configuration later.
- logdir: 必须与启动应用时的环境变量 NODE_LOG_DIR 相同，如果没有配置那么请使用 /tmp/ 或删除

### How to get app id and app token/secret.
您可以通过下述方式获取您的应用 Id 和应用 Token:

- 如果是第一次使用
  - 打开 https://node.console.aliyun.com
  - 通过阿里云账号登陆
  - 点击用户名
  - 添加应用->输入您的应用名->下一步
  - 获得 应用Id 和 应用Token
- 如果您已有应用id和Token
  - 登陆后点击应用名->右侧应用设置
  - 获得 应用Id 和 应用Token
  - 应用Id是一个数字，应用Token是一个字符串


## License

- alinode-all-in-one is released under the MIT license.
