<!--
 * @Author: cnak47
 * @Date: 2020-04-27 10:04:58
 * @LastEditors: cnak47
 * @LastEditTime: 2020-06-10 11:15:28
 * @Description: 
 -->

# 安装和配置filebeat

## 启动测试nginx，用于产生日志数据

```bash
docker run -d --log-driver=json-file --log-opt max-size=1k --log-opt max-file=5 --name webserver -p 9988:80 nginx
```

## 启动 filebeat

```bash

```
