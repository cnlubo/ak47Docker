<!--
Author: cnak47
Date: 2020-07-20 17:49:26
LastEditors: cnak47
LastEditTime: 2020-07-20 17:49:27
Description: 
-->

# 安装

```bash
wget https://raw.githubusercontent.com/grafana/loki/v1.5.0/production/docker-compose.yaml -O docker-compose.yaml
docker-compose -f docker-compose.yaml up

# 访问 grafana

127.0.0.1:3000
admin/admin
# 选择添加数据源 Loki 配置 Loki 源地址
http://loki:3100
保存完成后，切换到 grafana 左侧区域的Explore，即可进入到Loki的页面

```
