#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-11-29 12:04:27
# @LastEditors: cnak47
# @LastEditTime: 2019-12-27 19:35:33
# @Description:
###
# custom sid pdb pwd
docker run -d --name oracle -p 1521:1521 -p 5500:5500 \
   -e ORACLE_SID=testdb \
   -e ORACLE_PDB=testdb1 \
   -e ORACLE_PWD='ak47_12345' \
   -e ORACLE_CHARACTERSET=ZHS16GBK \
   -v /Users/ak47/oradata:/opt/oracle/oradata \
     oracle/database:12.2.0.1-ee