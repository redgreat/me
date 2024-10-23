%{
  title: "oceanbase单机环境部署",
  description: "",
  keywords: []
}
---

架构：
单机部署
硬件资源：8C16G 100G数据盘 
IP:192.168.200.148

组件： 
oceanbase-ce
obproxy-ce
obagent
ocp-express
prometheus
grafana

软件版本 observer4.1.0.0 社区版
使用官方提供obd工具安装

## 下载安装包
```shell
yum install wget -y

wget https://obbusiness-private.oss-cn-shanghai.aliyuncs.com/download-center/opensource/oceanbase-all-in-one/7/x86_64/oceanbase-all-in-one-4.1.0.0-100120230323143519.el7.x86_64.tar.gz?Expires=1681884878&OSSAccessKeyId=LTAI5tGVLeRRycCRGerZJMNC&Signature=D5q6aAfreY1c%2B4ALkDI5Y%2BpafDY%3D -O 'oceanbase.tar.gz'

tar -zxvf oceanbase.tar.gz

cd oceanbase-all-in-one/bin
```
## 安装部署工具obd
```shell
./install.sh
```
## 磁盘规划

LVM 管理方式，方便后期空间扩展

## 格式化磁盘
```shell
lsblk
fdisk /dev/sdb
n 
p
#1
t 
#8e
w
```
## 创建 pv vg lv 
```shell
fdisk -l
pvcreate /dev/sdb1
pvdisplay /dev/sdb1 -v
pvs

vgcreate vg_ob /dev/sdb1
vgdisplay vg_ob -v
vgs
#vgrename lvm_ob vg_ob
vgscan

lvcreate -L 99.5G -n lv_ob vg_ob
lvdisplay
lvs
lvscan
```
## 格式化为ext4
```shell
mkfs.ext4 /dev/vg_ob/lv_ob
```
## 挂载
```shell
mkdir -p /oceanbase
mount /dev/mapper/vg_ob-lv_ob /oceanbase
```
## 开机挂载 （路径一定要准，不然机器开不起来了）
```shell
vim /etc/fstab
/dev/mapper/vg_ob-lv_ob /oceanbase ext4 defaults 0 0
```
## 磁盘卸载，删除，后期扩容
```shell
umount /app
lvremove 
vgremove 
pvremove 
```
## 文件夹创建
```shell
mkdir -p /oceanbase/ob_data
mkdir -p /home/oceanbase/ob_log
mkdir -p /home/oceanbase/obproxy
mkdir -p /home/oceanbase/obagent
mkdir -p /home/oceanbase/ocp-server
mkdir -p /home/oceanbase/prometheus
mkdir -p /home/oceanbase/grafana
mkdir -p /home/oceanbase/observer/run
```
## 清空数据（重新安装时 desproy出错可能没清空时需要操作）
```shell
rm -rf /home/oceanbase/ob_log/*
rm -rf /home/oceanbase/obproxy/*
rm -rf /home/oceanbase/obagent/*
rm -rf /home/oceanbase/ocp-server/*
rm -rf /home/oceanbase/prometheus/*
rm -rf /home/oceanbase/grafana/*
rm -rf /home/oceanbase/observer/*
```
## 系统参数设置
### 时区
```shell
export TZ=CST-8
yum install ntpdate -y
ntpdate cn.ntp.org.cn
```
## 关闭透明大页
```shell
echo never > /sys/kernel/mm/transparent_hugepage/enabled
```
## 修改系统参数文件最大句柄数等

```shell
vim /etc/sysctl.conf
```
```shell
# for oceanbase
## 修改内核异步 I/O 限制
fs.aio-max-nr=1048576

## 网络优化
net.core.somaxconn = 2048
net.core.netdev_max_backlog = 10000 
net.core.rmem_default = 16777216 
net.core.wmem_default = 16777216 
net.core.rmem_max = 16777216 
net.core.wmem_max = 16777216

net.ipv4.ip_local_port_range = 3500 65535 
net.ipv4.ip_forward = 0 
net.ipv4.conf.default.rp_filter = 1 
net.ipv4.conf.default.accept_source_route = 0 
net.ipv4.tcp_syncookies = 0 
net.ipv4.tcp_rmem = 4096 87380 16777216 
net.ipv4.tcp_wmem = 4096 65536 16777216 
net.ipv4.tcp_max_syn_backlog = 16384 
net.ipv4.tcp_fin_timeout = 15 
net.ipv4.tcp_max_syn_backlog = 16384 
net.ipv4.tcp_tw_reuse = 1 
net.ipv4.tcp_tw_recycle = 1 
net.ipv4.tcp_slow_start_after_idle=0

vm.swappiness = 0
vm.min_free_kbytes = 2097152

# 此处为 OceanBase 数据库的 data 目录
kernel.core_pattern =/oceanbase/ob_data/core-%e-%p-%t
```

生效

```shell
shell
/sbin/sysctl -p 
/sbin/sysctl -a 
```
## 文件打开数限制
```shell
vim /etc/security/limits.conf

root soft nofile 655350
root hard nofile 655350
* soft nofile 655350
* hard nofile 655350
* soft stack 20480
* hard stack 20480
* soft nproc 655360
* hard nproc 655360
* soft core unlimited
* hard core unlimited
```
### 生效
```shell
ulimit -a
```
## 配置jdk，只有安装ocp时使用

### 下载镜像&&解压
```
wget https://repo.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz
mkdir -pv /usr/jdk1.8.0_202/ && tar -zxvf jdk-8u202-linux-x64.tar.gz -C /usr/
```
### 增加环境变量并使其生效
```
vim /etc/profile
#添加
JAVA_HOME=/usr/jdk1.8.0_202
CLASSPATH=.:$JAVA_HOME/lib.tools.jar
PATH=$JAVA_HOME/bin:$PATH
export JAVA_HOME CLASSPATH PATH
#生效
source /etc/profile
java -version
java version "1.8.0_202"
Java(TM) SE Runtime Environment (build 1.8.0_202-b08)
Java HotSpot(TM) 64-Bit Server VM (build 25.202-b08, mixed mode)
```

### 连接快捷方式（ocp只识别到bin）
```shell
ln -s /usr/jdk1.8.0_202/bin/java /usr/bin/java
```
## 单实例部署实例
[配置样例文件地址](https://nas.wongcw.cn:10003/d/s/tG363XWqcmzHr0QOLR5ME6lDNKKPh4Vp/N4VtygYyQf_uHc_jbnK4StwCjkjqLg95-Xb2gPHCWYQo)
```shell
#部署
obd cluster deploy zrcluster -c /root/oceanbase-all-in-one/conf/zrdt-single.yaml
#启动
obd cluster start zrcluster
#停止
obd cluster stop zrcluster
#查询
obd cluster display zrcluster
obd cluster list
#销毁
obd cluster destroy zrcluster
```

## 查看系统开发端口号
```shell
lsof -nP -iTCP -sTCP:LISTEN
```
## 登录sys租户
```shell
obclient -h192.168.200.148 -P2881 -uroot -p'9w3zFvV8uaBV6nhC' -Doceanbase -A
```
## 查看资源
```sql
select name,max_cpu,round(memory_size/1024/1024/1024,2) 'memory_size_GB',
round(log_disk_size/1024/1024/1024,2) 'log_size_GB'
from __all_unit_config;
```
## 改下系统单元占用
```sql
alter resource unit sys_unit_config max_cpu 1,memory_size '1G',LOG_DISK_SIZE = '6G';
```
## 查看可分配资源
```sql
select svr_ip,svr_port,zone,round((cpu_capacity_max-cpu_assigned_max),2) 'cpu_free_num',
cpu_capacity_max 'cpu_total_num',round((mem_capacity-mem_assigned)/1024/1024/1024,2) 'mem_free_GB', 
round(memory_limit/1024/1024/1024,2) 'mem_total_GB' from gv$ob_servers;
```
## 查看已分配资源
```sql
SELECT t1.tenant_name AS "租户名称",
t3.NAME AS "资源单位名称",
concat(svr_ip,":",svr_port) as "节点IP和端口",
t3.max_cpu AS "最大CPU",
t3.min_cpu AS "最小CPU",
ROUND(t3.MEMORY_SIZE/1024/1024/1024) AS "租户内存",
ROUND(t3.LOG_DISK_SIZE/1024/1024/1024) AS "日志磁盘最大值",
t3.MAX_IOPS AS "最大IOPS",
t4.NAME AS "资源池名称",
t2.ZONE AS "资源所属可用区"    
FROM OCEANBASE.DBA_OB_TENANTS t1,
     OCEANBASE.DBA_OB_UNITS t2,
     OCEANBASE.DBA_OB_UNIT_CONFIGS t3,
     OCEANBASE.DBA_OB_RESOURCE_POOLS t4
where t1.tenant_id = t4.tenant_id
AND t4.resource_pool_id=t2.resource_pool_id 
AND t4.unit_config_id=t3.unit_config_id
ORDER BY t1.tenant_name;
```
## 创建资源单元 （注意日志文件需要内存*6，不玩随时宕机）
```sql
create resource unit ut1 max_cpu 6,memory_size '10G',max_iops 10240 , IOPS_WEIGHT=1,LOG_DISK_SIZE = '20G';
```
## 创建资源池 （可以单可用区，需要副本的时候使用多可用区）
```sql
create resource pool p1 unit 'ut1',unit_num 1,zone_list=('zone1');
```
## 创建租户
```sql
create tenant zrmysql resource_pool_list=('p1') set ob_tcp_invited_nodes='%';
```
 > 社区版据说只支持mysql兼容类型

## 创建好租户后使用root连接租户并创建用户、数据库，给用户分权限
 > 注意：使用sys租户的root创建好新的租户后，首次登录新住户使用root账户，密码为空，进去先改密码！

```shell
obclient -h192.168.200.148 -P2881 -uroot@zrmysql -Doceanbase -A
```
```sql
alter user root identified by 'Lunz2017';
CREATE DATABASE whcenter;
CREATE USER user_wh@'%' IDENTIFIED BY 'Lunz2017';
grant all on *.* to user_wh;
```
## 以下不用执行，只是运维语句
## 修改、删除单元、池、租户
给UNIT增加日志空间限制
```sql
alter resource unit ut1 max_cpu 2,memory_size '2G',max_iops 102400 , IOPS_WEIGHT=1,LOG_DISK_SIZE = '12G'; 
DROP RESOURCE UNIT ut1;
```
## 修改租户资源
## 修改租户 zrmysql 的 Primary Zone 为 zone2
```sql
ALTER TENANT zrmysql primary_zone='zone2';
```
## 其中 F 表示副本类型为全功能型副本， zone4 为新增的 Zone 名称。
```sql
ALTER TENANT zrmysql locality="F@zone1,F@zone2,F@zone3,F@zone4";
```
## 不支持修改租户资源池
```sql
ALTER TENANT zrmysql resource_pool_list=('p2');
ERROR 1210 (HY000): Incorrect arguments to resource pool list
```
## 修改租户变量
```sql
ALTER TENANT zrmysql SET VARIABLES ob_tcp_invited_nodes='%';
```
## 删除租户
（1）当系统租户开启回收站功能时：表示删除的租户会进入回收站
```sql
DROP TENANT tenant_name;
```
（2）当系统租户关闭回收站功能时：表示延迟删除租户
```sql
DROP TENANT tenant_name;
```
（3）无论系统租户是否开启回收站功能：删除的租户均不进入回收站，仅延迟删除租户
```sql
DROP TENANT tenant_name PURGE;
```
（4）无论系统租户是否开启回收站功能：均可以立刻删除租户
```sql
DROP TENANT tenant_name FORCE;
```

## 租户添加白名单
```sql
ALTER TENANT zrmysql SET VARIABLES ob_tcp_invited_nodes='%';
```
## 切换系统租户
```sql
ALTER SYSTEM CHANGE TENANT zrmysql;
```
## 修改密码
```sql
update __all_user set passwd='Lunz2017' where user_name='root'; # 明文方式，不建议
alter user user_wh identified by 'Lunz2017';
```