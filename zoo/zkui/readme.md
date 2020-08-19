<!--
 * @Author: cnak47
 * @Date: 2020-07-30 15:35:25
 * @LastEditors: cnak47
 * @LastEditTime: 2020-07-31 14:44:04
 * @Description: 
-->

# zkui

## install

```bash
# 修改maven 下载源
# 找到 conf 目录中的 settings.xml
# 修改maven 本地仓库地址
#找到<localRepository> </localRepository>打开注释修改如下：
<localRepository>D:\workspace\MavenRepository</localRepository>
# 添加阿里源 ，找到  <mirrors>  </ mirrors>标签，在标签内部 添加内容如下
<mirror>
    <id>aliyunmaven</id>
    <mirrorOf>*</mirrorOf>
    <name>阿里云公共仓库</name>
    <url>https://maven.aliyun.com/repository/public</url>
</mirror>
# 下载zkui
git clone https://github.com/DeemOpen/zkui.git
cd zkui
# 编译安装
mvn clean install
```
