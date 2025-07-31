%{
  title: "KingbaseES(MySQL兼容版)体验"
}
---

## 基础环境

使用win11上的HyperV创建虚拟机，配置2C4G

### 操作系统
OracleLinux 9.6U6
```shell
[root@tidb ~]# uname -a
Linux tidb 6.12.0-101.33.4.3.el9uek.x86_64 #1 SMP PREEMPT_DYNAMIC Mon Jul 14 18:34:15 PDT 2025 x86_64 x86_64 x86_64 GNU/Linux
```

操作系统下载地址：[Oracle Linux 9.6U6](https://yum.oracle.com/oracle-linux-isos.html)  
数据库安装文件下载地址：[KingbaseES V9R3C11(MySQL兼容版)](https://www.kingbase.com.cn/download.html)

### IP配置

```shell
[root@tidb ~]# ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:13:e3:21 brd ff:ff:ff:ff:ff:ff
    inet 172.16.1.105/24 brd 172.16.1.255 scope global noprefixroute eth0
       valid_lft forever preferred_lft forever
```

按照官方文档指示，逐步安装，[KingbaseES安装文档](https://bbs.kingbase.com.cn/docHtml?recId=ef7404928de44316a3e72c84e64af712&url=aHR0cHM6Ly9iYnMua2luZ2Jhc2UuY29tLmNuL2tpbmdiYXNlLWRvYy92OS4zLjExL2luc3RhbGwtdXBkYXRhL2luc3RhbGwtbGludXgvaW5kZXguaHRtbA)

### 查看内存、临时表空间

```shell
[root@tidb ~]# free -m
               total        used        free      shared  buff/cache   available
Mem:            3462         467        2574           8         644        2994
Swap:           4039           0        4039

[root@tidb ~]# df -hT
Filesystem          Type      Size  Used Avail Use% Mounted on
devtmpfs            devtmpfs  4.0M     0  4.0M   0% /dev
tmpfs               tmpfs     1.7G     0  1.7G   0% /dev/shm
tmpfs               tmpfs     693M  8.5M  685M   2% /run
efivarfs            efivarfs  128M   30K  128M   1% /sys/firmware/efi/efivars
/dev/mapper/ol-root xfs        64G  2.3G   62G   4% /
/dev/sda2           xfs       960M  305M  656M  32% /boot
/dev/mapper/ol-home xfs        31G  254M   31G   1% /home
/dev/sda1           vfat      599M  7.2M  592M   2% /boot/efi
tmpfs               tmpfs     347M     0  347M   0% /run/user/0
```

> **注意：** 需保障 /tmp挂载点的磁盘空间大于10G，或者内存+Swap大于10G。

### 修改内核参数
```shell
vim /etc/sysctl.conf

# 添加
fs.aio-max-nr= 1048576
fs.file-max= 6815744
kernel.shmall= 2097152
kernel.shmmax= 4294967295
kernel.shmmni= 4096
kernel.sem= 250 32000 100 128
net.ipv4.ip_local_port_range= 9000 65500
net.core.rmem_default= 262144
net.core.rmem_max= 4194304
net.core.wmem_default= 262144
net.core.wmem_max= 1048576

# 生效
/sbin/sysctl -p
/sbin/sysctl -a

```

### 修改资源使用参数
```shell
vim /etc/security/limits.conf

# 添加
* soft nofile 65536
* hard nofile 65535
* soft nproc 65536
* hard nproc 65535
* soft core unlimited
* hard core unlimited
```

### RemoveIPC参数修改

```shell
vim /etc/systemd/logind.conf
# 查找 RemoveIPC 确保
RemoveIPC=no

# 生效
systemctl daemon-reload
systemctl restart systemd-logind.service
```

### 关闭防火墙
```shell
systemctl stop firewalld.service
systemctl disable firewalld.service
```

### 创建用户
```shell
useradd -m -s /bin/bash kingbase
passwd kingbase
```

### 设置安装目录
```shell
mkdir -p /opt/Kingbase/ES/V9
chmod o+rwx /opt/Kingbase/ES/V9
```

### 数据目录
```shell
su - kingbase
mkdir /home/kingbase/kdb

# 镜像挂载目录
mkdir -p /home/kingbase/KingbaseESV9
```

### 安装包的挂载与取消
```shell
su - root
mount KingbaseES_V009R003C011B0003_Lin64_install.iso /home/kingbase/KingbaseESV9
```

安装完成后取消挂在
```shell
su - root
umount /home/kingbase/KingbaseESV9
```

## 安装KingbaseES
KingbaseES支持图形化安装，也支持命令行安装，我装的系统是最小化版没桌面这里选的命令行安装方式。

### 安装包传输
这里推荐个好用的scp传输工具 Win  
去英文官网[下载](https://winscp.net/eng/download.php)，有汉化包，不要去中文站下收费得。

### 启动安装程序
国产化的应用，支持中文是必要的，

```shell
echo $LANG
```
如果系统显示值包含“zh_CN”，则为中文语言，安装程序会显示中文内容。否则，您可以执行如下命令修改语言设置为中文： 

```
export LANG=zh_CN.UTF-8
```

### 执行安装程序

使用kingbase用户执行
```shell
su - kingbase
sh setup.sh -i console
```
### 安装遇到问题
```shell
[kingbase@tidb KingbaseESV9]$ sh setup.sh -i console
setup.sh: line 171: fc-cache: command not found
Now launch installer...
Preparing to install
Extracting the JRE from the installer archive...
Unpacking the JRE...
setup/install.bin: line 798: tar: command not found

Complete.
```

#### 解决方法
安装tar包
```shell
dnf install tar
```

### 继续安装过程
按回车阅读协议
```shell
Last login: Wed Jul 30 17:09:33 CST 2025 on pts/0
[kingbase@tidb ~]$ cd KingbaseESV9/
[kingbase@tidb KingbaseESV9]$ sh setup.sh -i console
setup.sh: line 171: fc-cache: command not found
Now launch installer...
Preparing to install
Extracting the JRE from the installer archive...
Unpacking the JRE...
Extracting the installation resources from the installer archive...
Configuring the installer for this system's environment...

Launching installer...

===============================================================================
KingbaseES V9                                    (created with InstallAnywhere)
-------------------------------------------------------------------------------

Preparing CONSOLE Mode Installation...

===============================================================================
Welcome
-------

This installer will guide you through the installation of KingbaseES V9.

It is strongly recommended that you quit all programs before continuing with
this installation. You may cancel this installation by typing 'quit'.

KingbaseES Version: V9
Kingbase Type:BMJ-NO
Installer Version: V009R003C011
Install DATE:202507300514

Kingbase Inc.
        http://www.kingbase.com.cn

PRESS <ENTER> TO CONTINUE:
...

===============================================================================
License Agreement
-----------------

Installation and Use of KingbaseES V9 Requires Acceptance of the Following
License Agreement:
```

#### 接受协议
输入Y 接受协议
```shell
DO YOU ACCEPT THE TERMS OF THIS LICENSE AGREEMENT? (Y/N): Y
```

#### 选择安装类型
选择完全安装 1
```shell
===============================================================================
Choose Install Set
------------------

Please choose the Install Set to be installed by this installer.

  ->1- Full
    2- Client

    3- Custom

ENTER THE NUMBER FOR THE INSTALL SET, OR PRESS <ENTER> TO ACCEPT THE DEFAULT
   : 1
```

#### 选择License文件
如果测试就直接输入回车默认Trial
```shell
===============================================================================
Choose License File
-------------------

Use the Trial license if no license is selected.
Please replace the offical license before expiration.

File Path :
```

#### 安装路径选择
```shell
===============================================================================
Choose Install Folder
---------------------

Please choose a destination folder for this installation.

Where would you like to install?

  Default Install Folder: /opt/Kingbase/ES/V9

ENTER AN ABSOLUTE PATH, OR PRESS <ENTER> TO ACCEPT THE DEFAULT
      :
```

#### 安装信息汇总
```shell
===============================================================================
Pre-Installation Summary
------------------------

Please Review the Following Before Continuing:

Product Name:
    KingbaseES V9

Install Folder:
    /opt/Kingbase/ES/V9

Product Features:
    SERVER,
    INTERFACE,
    DEPLOY,
    KSTUDIO,
    KDTS

Install Disk Space Information
    Require Disk space : 5112 MB           Free Disk Space :  MB



PRESS <ENTER> TO CONTINUE:
```

#### 确认安装
```shell
===============================================================================
Ready To Install
----------------

InstallAnywhere is now ready to install KingbaseES V9 onto your system at the
following location:

   /opt/Kingbase/ES/V9

PRESS <ENTER> TO INSTALL:
```

#### 选择数据目录

```shell
===============================================================================
Choose a Folder for data directory
----------------------------------

Please choose a folder. The folder must be empty.

Data folder (Default: /opt/Kingbase/ES/V9/data):
```

#### 选择端口号
这里使用默认值
```shell
===============================================================================
Port
----

Please enter database service listened port， default 54321.

Port (Default: 54321):
```

#### 选择管理员用户
```shell
===============================================================================
User
----

Please enter database administrator user name.

User (Default: system):
```

#### 设置管理员密码
```
===============================================================================
Enter Password
--------------


Please Enter the Password: Please Enter the Password:*

===============================================================================
Enter Password again
--------------------


Please Enter the Password Again: Please Enter the Password Again:*

```
#### 选择字符集
```
===============================================================================
Server Encoding
---------------

Please enter server character set encoding.

    1- default
  ->2- UTF8
    3- GBK
    4- GB2312
    5- GB18030

ENTER THE NUMBER FOR YOUR CHOICE, OR PRESS <ENTER> TO ACCEPT THE DEFAULT:
```

#### 选择Locale
```
===============================================================================
Locale
------

Please enter the Database Locale.

    1- C
  ->2- zh_CN.UTF-8
    3- en_US.UTF-8

ENTER THE NUMBER FOR YOUR CHOICE, OR PRESS <ENTER> TO ACCEPT THE DEFAULT:
```

#### 遇到Locale错误

```
===============================================================================
ERROR
-----

Locale not supported by the OS, please select another one.
```

##### 修正方法
添加操作系统中文包
```
dnf install glibc-langpack-zh.x86_64
echo LANG=zh_CN.UTF-8 > /etc/locale.conf
source /etc/locale.conf
locale -a
```
#### 选择兼容模式
本次体验MySQL兼容版
```
===============================================================================
Database Mode
-------------

Please enter database mode.

  ->1- MySQL

ENTER THE NUMBER FOR YOUR CHOICE, OR PRESS <ENTER> TO ACCEPT THE DEFAULT:
```

#### 设置大小写敏感性
```
===============================================================================
Case Sensitivity
----------------

Please enter the case sensitivity.

    1- YES
  ->2- NO

ENTER THE NUMBER FOR YOUR CHOICE, OR PRESS <ENTER> TO ACCEPT THE DEFAULT:
```

#### 选择Block Size
```
===============================================================================
Block Size
----------

Please enter block size used in storing data.

  ->1- 8k
    2- 16k
    3- 32k

ENTER THE NUMBER FOR YOUR CHOICE, OR PRESS <ENTER> TO ACCEPT THE DEFAULT:
```

#### 选择验证方法
```
===============================================================================
Authentication Method
---------------------

Please enter the authentication method.

  ->1- scram-sha-256
    2- scram-sm3
    3- sm4
    4- sm3

ENTER THE NUMBER FOR YOUR CHOICE, OR PRESS <ENTER> TO ACCEPT THE DEFAULT:

```

#### 设置自定义参数
```
===============================================================================
Custom
------

Please enter database custom parameters.

Custom (Default:  ):
```

#### 最终确认
```
===============================================================================
Tips
----

The database will be initialized, which may take some time. Please be patient.

PRESS <ENTER> TO CONTINUE:
```

#### 完成安装
```
===============================================================================
Installation Complete
---------------------

Congratulations. KingbaseES V9 has been successfully installed to:

/opt/Kingbase/ES/V9

If you want to register KingbaseES V9 as OS service, please run

    /opt/Kingbase/ES/V9/install/script/root.sh

PRESS <ENTER> TO EXIT THE INSTALLER:
```

### 执行root.sh

```
su - root
sh /opt/Kingbase/ES/V9/install/script/root.sh

[root@tidb ~]# sh /opt/Kingbase/ES/V9/install/script/root.sh
Starting KingbaseES V9:
等待服务器进程启动 .... 完成
服务器进程已经启动
KingbaseES V9 started successfully
```
### 服务启停命令

```
#启动服务
sys_ctl -w start -D /opt/Kingbase/ES/V9/data -l "/opt/Kingbase/ES/V9/data/sys_log/startup.log"
#停止服务
sys_ctl stop -m fast -w -D /opt/Kingbase/ES/V9/data
```
### 查看安装日志
日志具体位置：

```
cd /opt/Kingbase/ES/V9/install/Logs
tail -200 KingbaseES_V9_Install_07_30_2025_17_23_47.log
```

### 查看系统端口号
```
netstat -tunlp | grep 54321
```

## 开始体验MySQL兼容性

### 创建用户和数据库
使用金仓的win客户端连接工具，登录SYSTEM用户，创建业务使用账号、数据库：

```sql
CREATE USER user_wh WITH PASSWORD 'xxx';

ALTER USER user_wh CREATEDB;

CREATE DATABASE whcenter WITH OWNER = user_wh ENCODING = 'UTF8';
GRANT ALL ON DATABASE whcenter TO user_wh;
ALTER DATABASE whcenter SET search_path = whcenter, public;

-- 授予目标 Schema 的表读取权限
GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO user_wh;

-- 授予目标 Schema 的 USAGE 权限
GRANT USAGE ON SCHEMA PUBLIC TO user_wh;
```

### 数据迁移测试
使用金仓提供的win数据迁移工具KDTS  
本次迁移测试项目是日常运维的一套仓储系统，里面包含大量存储过程、自定义函数、视图，少部分表带框架，查看数据、结构迁移难度以及SQL兼容性。

#### 迁移过程
迁移需要配置数据源链接、目标链接  
新建迁移任务，迁移任务可以自定义迁移对象、迁移细节包括线程池、字段类型转换，错误处理等都可以配置。

#### 首次迁移结果
看错误详情，存储过程和自定义函数的创建语法不能自动转换，需要手动创建。部分外键约束在迁移的时候不能自动设置忽略写入数据，表数据部分也会部分写入失败。

总体来说自动转换所占百分比还是挺高的，重点在于自定义函数和存储过程的逻辑重写。

迁移过程中，目标库性能消耗不是很大，但也取决于迁移任务设置的线程池大小、迁移对象数量等因素。

## MySQL兼容性测试结果

### 数据库表结构

通过PostgreSQL客户端连接KingbaseES，可以查看数据库中的表结构：

```sql
-- 查看whcenter模式下的所有表
\dt whcenter.*

-- 查看特定表的结构
\d whcenter.wh_inventoryturnover
```

示例表结构：

```
                     Table "whcenter.wh_inventoryturnover"
       Column        |          Type          | Collation | Nullable | Default
---------------------+------------------------+-----------+----------+---------
 Id                  | bigint                 |           | not null |
 MainPartId          | character(12)          | ci_x_icu  |          |
 MainPartName        | character varying(100) | ci_x_icu  |          |
 ParentWarehouseId   | character(12)          | ci_x_icu  |          |
 ParentWarehouseName | character varying(100) | ci_x_icu  |          |
 WarehouseId         | character(12)          | ci_x_icu  |          |
 WarehouseName       | character varying(100) | ci_x_icu  |          |
 MaterialId          | character(12)          | ci_x_icu  |          |
 MaterialName        | character varying(200) | ci_x_icu  |          |
 MaterialType        | character varying(50)  | ci_x_icu  |          |
 LastNum             | integer                |           |          |
 ThisNum             | integer                |           |          |
 ThisOut             | integer                |           |          |
 InventoryTurnover   | numeric(18,5)          |           |          |
 DCOInventory        | integer                |           |          |
 CheckDate           | datetime               |           |          |
Indexes:
    "PRIMARY_FF0A03A" PRIMARY KEY, btree (Id NULLS FIRST)
    "NON-MaterialId_A6835108" btree (MaterialId NULLS FIRST)
```

### DML操作兼容性测试

#### 1. 用户变量支持

```sql
-- 设置和使用用户变量
SET @var1 = 1; 
SELECT @var1;
```

结果：
```
 @var1
-------
     1
```

#### 2. REPLACE INTO语句

```sql
-- 创建测试表
CREATE TEMPORARY TABLE test_replace (id INT PRIMARY KEY, name VARCHAR(50)); 
-- 使用REPLACE INTO插入数据
REPLACE INTO test_replace VALUES (1, 'Test');
```

结果：
```
CREATE TABLE
INSERT 0 1
```

#### 3. INSERT ... ON DUPLICATE KEY UPDATE

```sql
-- 创建测试表并插入初始数据
CREATE TEMPORARY TABLE test_replace (id INT PRIMARY KEY, name VARCHAR(50)); 
INSERT INTO test_replace VALUES (1, 'Test'); 
-- 使用ON DUPLICATE KEY UPDATE语法
INSERT INTO test_replace VALUES (1, 'Updated') ON DUPLICATE KEY UPDATE name = 'Updated'; 
SELECT * FROM test_replace;
```

结果：
```
 id |  name
----+---------
  1 | Updated
```

#### 4. UPDATE语句中的LIMIT子句

```sql
-- 创建测试表并插入测试数据
CREATE TEMPORARY TABLE test_limit (id INT, value VARCHAR(50)); 
INSERT INTO test_limit VALUES (1, 'A'), (2, 'B'), (3, 'C'); 
-- 使用LIMIT子句限制更新行数
UPDATE test_limit SET value = 'Updated' LIMIT 2; 
SELECT * FROM test_limit;
```

结果：
```
 id |  value
----+---------
  3 | C
  1 | Updated
  2 | Updated
```

#### 5. 多表更新

```sql
-- 创建测试表并插入测试数据
CREATE TEMPORARY TABLE t1 (id INT, value VARCHAR(50)); 
CREATE TEMPORARY TABLE t2 (id INT, value VARCHAR(50)); 
INSERT INTO t1 VALUES (1, 'A'), (2, 'B'); 
INSERT INTO t2 VALUES (1, 'X'), (2, 'Y'); 
-- 使用多表更新语法
UPDATE t1, t2 SET t1.value = t2.value WHERE t1.id = t2.id; 
SELECT * FROM t1;
```

结果：
```
 id | value
----+-------
  1 | X
  2 | Y
```

### 查询语句兼容性

#### GROUP BY WITH ROLLUP

```sql
-- 使用GROUP BY WITH ROLLUP进行多级汇总
SELECT WarehouseId, MaterialId, SUM(ThisNum) as TotalNum 
FROM whcenter.wh_inventoryturnover 
GROUP BY WarehouseId, MaterialId WITH ROLLUP 
LIMIT 10;
```

### 接口开发兼容性

#### MySQL客户端连接

尝试使用MySQL Shell连接KingbaseES：

```shell
& "D:\soft\MySQL\MySQL Shell 8.0\bin\mysqlsh.exe" --mysql --host=172.16.1.105 --port=54321 --user=user_wh --password=xxxx --schema=whcenter
```

目前连接失败，可能需要进一步配置：

```
MySQL Error 2013 (HY000): Lost connection to MySQL server at 'waiting for initial communication packet', system error: 10060
```

## 总结

KingbaseES MySQL兼容版在DML操作方面表现出很好的兼容性，支持：

1. MySQL用户变量
2. REPLACE INTO语句
3. INSERT ... ON DUPLICATE KEY UPDATE语法
4. UPDATE语句中的LIMIT子句
5. 多表更新语法
6. GROUP BY WITH ROLLUP多级汇总

在客户端连接方面，目前通过PostgreSQL客户端可以正常连接和操作，但通过MySQL协议连接还需要进一步配置。

对于数据迁移，KDTS工具可以自动转换大部分表结构和数据，但存储过程和自定义函数需要手动调整。




