%{
  title: "oceanbase-oms环境部署"
}
---

# 安装OMS
类似DTS数据迁移工具

## 磁盘规划
```
lsblk
fdisk /dev/sdb
n 
p
#1
t 
#8e
w

fdisk -l
pvcreate /dev/sdb1
pvdisplay /dev/sdb1 -v
pvs

vgcreate vg_docker /dev/sdb1
vgdisplay vg_docker -v
vgs
vgscan

lvcreate -L 99.5G -n lv_docker vg_docker
lvdisplay
lvs
lvscan
```
## 格式化、挂载磁盘
```
mkfs.ext4 /dev/vg_docker/lv_docker
mkdir -p /data/docker
mount /dev/mapper/vg_docker-lv_docker /data/docker
vim /etc/fstab
/dev/mapper/vg_docker-lv_docker /data/docker ext4 defaults 0 0
```
## 安装docker
```
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```

##  更换Docker存储卷位置
```
mkdir -p /oceanbase/docker

vim /etc/docker/daemon.json

{
"registry-mirrors": ["https://mirror.ccs.tencentyun.com/"],
"data-root":"/data/docker",
"live-restore": true
}
```
## 启动
```
systemctl start docker
systemctl daemon-reload
systemctl restart docker
# 设置开机自启动
systemctl enable docker
systemctl start docker
```

### 查看docker内容器
```
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}\t{{.Status}}"
```
## 下载镜像
```
wget https://obbusiness-private.oss-cn-shanghai.aliyuncs.com/download-center/opensource/oms/4.0.0_CE_BP1/oms_4.0.0-ce_bp1.tar.gz?Expires=1681897811&OSSAccessKeyId=LTAI5tGVLeRRycCRGerZJMNC&Signature=GIshAuI%2Fe8cClKOlwNDdhfa7h1s%3D
```
## 加载镜像
```
docker load -i oms_4.0.0-ce_bp1.tar.gz
```
## 查看镜像
```
docker images
```
## 生成部署脚本
```
sudo docker run -d --net host --name oms-config-tool reg.docker.alibaba-inc.com/oceanbase/oms:feature_4.0.0-ce_bp1 bash && sudo docker cp oms-config-tool:/root/docker_remote_deploy.sh . && sudo docker rm -f oms-config-tool
```
## 启动
[配置样例文件地址](https://nas.wongcw.cn:10003/d/s/tG362uvOvwfZ7EU8pkxbnxa738ojuBt0/gNNU1zXLN3IoJptOCcImDl0GtzklH7_p-Fb2A3zuWYQo)
```
# 样例
sh docker_remote_deploy.sh -o <部署工具映射目录> -c <已有 config.yaml 配置文件地址> -i <本机 IP 地址> -d <OMS_IMAGE>
# 交互式console
sh docker_remote_deploy.sh -o /data/oms -i 192.168.200.148 -d reg.docker.alibaba-inc.com/oceanbase/oms:feature_4.0.0-ce_bp1
# 配置文件
sh docker_remote_deploy.sh -o /data/oms -c /data/oms/config.yaml -i 192.168.200.148 -d reg.docker.alibaba-inc.com/oceanbase/oms:feature_4.0.0-ce_bp1
```
## 查看
```
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}\t{{.Status}}"
docker stop 
lsof -nP -iTCP -sTCP:LISTEN
```

## 配置文件样例
# OMS 社区版元数据库信息
oms_meta_host: ${oms_meta_host}
oms_meta_port: ${oms_meta_port}
oms_meta_user: ${oms_meta_user}
oms_meta_password: ${oms_meta_password}
     
# 用户可以自定义以下三个数据库的名称，OMS 社区版部署时会在元信息库中创建出这三个数据库
drc_rm_db: ${drc_rm_db}
drc_cm_db: ${drc_cm_db}
drc_cm_heartbeat_db: ${drc_cm_heartbeat_db}
     
# 用于消费 OceanBase 增量的用户
# 当需要从 OceanBase 数据库消费增量日志时，请在 sys 租户下创建用户
# drc user 需要在待迁移的 OceanBase 集群 sys 租户下创建，然后在 OMS 社区版的 config.yaml 文件中指定
drc_user: ${drc_user}
drc_password: '${drc_password}'
     
# OMS 社区版集群配置
# 单节点部署时，通常配置为当前 OMS 社区版机器 IP（建议使用内网 IP）
cm_url: ${cm_url}
cm_location: ${cm_location}
# 单节点部署时，无需设置 cm_region
# cm_region: ${cm_region}
# 单节点部署时，无需设置 cm_region_cn
# cm_region_cn: ${cm_region_cn}
cm_is_default: true
cm_nodes:
 - ${cm_nodes}
     
# 时序数据库配置
# 默认值为 false。如果您需要开启指标汇报功能，请设置为 true
# tsdb_enabled: false 
# 当 tsdb_enabled 为 true 时，请取消下述参数的注释并根据实际情况填写
# tsdb_service: 'INFLUXDB'
# tsdb_url: '${tsdb_url}'
# tsdb_username: ${tsdb_user}
# tsdb_password: ${tsdb_password}