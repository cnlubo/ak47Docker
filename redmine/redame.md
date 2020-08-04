<!--
Author: cnak47
Date: 2020-08-02 21:06:44
LastEditors: cnak47
LastEditTime: 2020-08-02 21:45:14
Description: 
-->
<!--
Author: cnak47
Date: 2020-08-02 21:06:44
LastEditors: cnak47
LastEditTime: 2020-08-02 21:06:45
Description: 
-->

# redmine

## 启动

```bash
# Step 1. Launch a postgresql container
docker run --name=postgresql-redmine -d \
  --env='DB_NAME=redmine_production' \
  --env='DB_USER=redmine' --env='DB_PASS=password' \
  --volume=/Users/ak47/Documents/docker/redmine/postgresql:/var/lib/postgresql \
  cnlubo/postgresql:12
# Step 2. Launch the redmine container
docker run --name=redmine -d \
  --link=postgresql-redmine:postgresql --publish=10083:80 \
  --env='REDMINE_PORT=10083' \
  --volume=/Users/ak47/Documents/docker/redmine/redmine:/home/redmine/data \
  --volume=/Users/ak47/Documents/docker/redmine/redmine-logs:/var/log/redmine/ \
  sameersbn/redmine:4.1.1-5

#Point your browser to http://localhost:10083 and login using the default username and password:
# username: admin
# password: admin

```
