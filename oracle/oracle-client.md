# Oracle Instant Client

## mac 安装配置

### 安装包下载

<https://www.oracle.com/database/technologies/instant-client/macos-intel-x86-downloads.html#ic_osx_inst>

四个文件

- instantclient-basic-macos.x64-19.3.0.0.0dbru.zip
- instantclient-sqlplus-macos.x64-19.3.0.0.0dbru.zip
- instantclient-tools-macos.x64-19.3.0.0.0dbru.zip
- instantclient-sdk-macos.x64-19.3.0.0.0dbru.zip

### 安装配置

```bash
# 创建安装目录解压文件
mkdir -p ~/tools/oracle
# 按顺序解压文件
unzip instantclient-basic-macos.x64-19.3.0.0.0dbru.zip
unzip instantclient-sqlplus-macos.x64-19.3.0.0.0dbru.zip
unzip instantclient-tools-macos.x64-19.3.0.0.0dbru.zip
unzip instantclient-sdk-macos.x64-19.3.0.0.0dbru.zip
cd instantclient_19_3
cp sdk/* .
# 配置环境变量
# ~/.zshrc 增加
export ORACLE_HOME=/Users/ak47/tools/oracle/instantclient_19_3/
export DYLD_LIBRARY_PATH=$ORACLE_HOME
export LD_LIBRARY_PATH=$ORACLE_HOME
export PATH=$PATH:$ORACLE_HOME
```
