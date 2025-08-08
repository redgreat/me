%{
  title: "Redis 5.0 CentOS Stream 9主从搭建指南"
}
---

## 环境说明
- 操作系统：CentOS Stream 9
- Redis版本：5.0.x
- 主节点：172.50.1.24
- 从节点：172.50.1.25

## 一、系统准备

### 1.1 安装依赖
```bash
dnf update -y
dnf install -y gcc gcc-c++ make wget tcl git

# 检查gcc版本
gcc --version
```

### 1.2 防火墙和SELinux配置
```bash
# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# SELinux配置
getenforce
setenforce 0

# 禁用SELinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```

## 二、Redis安装

### 源码编译安装Redis 5.0.x
```bash
# 创建Redis用户
useradd -r -s /bin/false redis

# 创建安装目录
mkdir -p /usr/local/redis
cd /usr/local/redis

# 创建数据目录
mkdir -p /data/redis
chown -R redis:redis /data/redis
chmod 750 /data/redis

# 日志目录
mkdir -p /var/log/redis
chown -R redis:redis /var/log/redis
chmod 750 /var/log/redis

# 配置文件目录
mkdir -p /etc/redis
chown -R redis:redis /etc/redis
chmod 750 /etc/redis

# 下载Redis 5.0.14（稳定版本）
wget http://download.redis.io/releases/redis-5.0.14.tar.gz

# 解压
tar -zxvf redis-5.0.14.tar.gz
cd redis-5.0.14

# 编译
make && make install
```

## 三、 系统服务配置

### 3.1 主节点配置文件
```bash
# 编辑配置文件
vim /etc/redis/redis_master.conf

```bash
# 基本配置
bind 0.0.0.0
port 6379
timeout 300
tcp-keepalive 300
tcp-backlog 511

# 守护进程配置
daemonize yes
pidfile /var/run/redis_master.pid
logfile /var/log/redis/redis_master.log
loglevel notice

# 数据配置
dir /data/redis
dbfilename dump.rdb
appendfilename "appendonly.aof"
appendonly yes
appendfsync everysec

# 内存配置
maxmemory 2gb
maxmemory-policy allkeys-lru

# 安全配置
protected-mode no
requirepass xxxxxxxxx

# 持久化配置
save 900 1
save 300 10
save 60 10000
rdbcompression yes
rdbchecksum yes

# 慢查询日志
slowlog-log-slower-than 10000
slowlog-max-len 128

# 客户端配置
maxclients 10000

# AOF配置
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes

# 网络配置
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
```

```bash
chown redis:redis /etc/redis/redis_master.conf
chmod 640 /etc/redis/redis_master.conf
```

### 3.2 从节点配置文件
vim /etc/redis/redis_slave.conf

```bash
# 基本配置
bind 0.0.0.0
port 6379
timeout 300
tcp-keepalive 300
tcp-backlog 511

# 守护进程配置
daemonize yes
pidfile /var/run/redis_slave.pid
logfile /var/log/redis/redis_slave.log
loglevel notice

# 数据配置
dir /data/redis
dbfilename dump.rdb
appendfilename "appendonly.aof"
appendonly yes
appendfsync everysec

# 内存配置
maxmemory 2gb
maxmemory-policy allkeys-lru

# 安全配置
protected-mode no
requirepass xxxxxxxxx
masterauth xxxxxxxxx

# 主从配置
replicaof 172.50.1.24 6379
replica-read-only yes

# 持久化配置
save 900 1
save 300 10
save 60 10000
rdbcompression yes
rdbchecksum yes

# 慢查询日志
slowlog-log-slower-than 10000
slowlog-max-len 128

# 客户端配置
maxclients 10000

# AOF配置
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes

# 网络配置
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
```

```bash
chown redis:redis /etc/redis/redis_slave.conf
chmod 640 /etc/redis/redis_slave.conf
```

### 3.3 创建systemd服务文件
主：
vim /etc/systemd/system/redis.service
```bash
[Unit]
Description=Redis In-Memory Data Store (Port 6379)
After=network.target

[Service]
Type=forking
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis_master.conf
ExecStop=/usr/local/bin/redis-cli -p 6379 -a xxxxxxxxx shutdown
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```
从：
vim /etc/systemd/system/redis.service
```bash
[Unit]
Description=Redis In-Memory Data Store (Port 6379)
After=network.target

[Service]
Type=forking
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis_slave.conf
ExecStop=/usr/local/bin/redis-cli -p 6379 -a xxxxxxxxx shutdown
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 3.4 启动和管理服务
```bash
# 启动Redis服务
systemctl daemon-reload
systemctl start redis
systemctl enable redis

# 查看状态
systemctl status redis

# 查看日志
journalctl -u redis -f
```

## 四、验证主从配置

### 4.1 主节点验证
```bash
# 连接主节点
redis-cli -h 172.50.1.24 -a your_redis_password

# 查看主从信息
info replication

172.50.1.24:6379> info replication
# Replication
role:master
connected_slaves:1
slave0:ip=172.50.1.25,port=6379,state=online,offset=112,lag=1
master_replid:a9de7b70741b96324cea556c3337b371fd779c1b
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:112
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:112

```

### 4.2 从节点验证
```bash
# 连接从节点
redis-cli -h 172.50.1.25 -a xxxxxxxxx

# 查看主从信息
info replication

172.50.1.25:6379> info replication
# Replication
role:slave
master_host:172.50.1.24
master_port:6379
master_link_status:up
master_last_io_seconds_ago:1
master_sync_in_progress:0
slave_repl_offset:756
slave_priority:100
slave_read_only:1
connected_slaves:0
master_replid:a9de7b70741b96324cea556c3337b371fd779c1b
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:756
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:756
```

## 五、故障转移与数据恢复

### 5.1 故障场景说明
当主节点（172.50.1.24）发生宕机或不可用时，需要将现有的从节点（172.50.1.25）提升为新的主节点，确保服务可用性。Redis 5.0不支持自动故障转移，需要手动操作。

### 5.2 故障检测与确认

#### 5.2.1 检查主节点状态
```bash
# 在主节点服务器上检查Redis进程
ps aux | grep redis

# 检查Redis服务状态
systemctl status redis

# 检查端口是否监听
netstat -tlnp | grep 6379

# 尝试连接主节点（从节点服务器上执行）
redis-cli -h 172.50.1.24 -a xxxxxxxxx ping
```

#### 5.2.2 确认主从同步状态
```bash
# 在从节点上检查主从状态
redis-cli -h 172.50.1.25 -a xxxxxxxxx info replication

# 查看主从连接状态，如果master_link_status为down，说明主节点已不可用
```

### 5.3 从节点升主操作（一般不需要，从节点只做只读实例、数据备份使用）

#### 5.3.1 停止从节点复制
```bash
# 连接从节点
redis-cli -h 172.50.1.25 -a xxxxxxxxx

# 停止复制，将从节点提升为主节点
127.0.0.1:6379> SLAVEOF NO ONE

# 验证节点已提升为主节点
127.0.0.1:6379> info replication
```

#### 5.3.2 修改配置文件
```bash
# 备份原配置文件
cp /etc/redis/redis_slave.conf /etc/redis/redis_slave.conf.backup

# 修改从节点配置文件，移除主从配置
vim /etc/redis/redis_slave.conf
```

需要修改或注释掉的配置：
```bash
# 注释掉原有的主从配置
# replicaof 172.50.1.24 6379
# masterauth xxxxxxxxx

# 确保从节点可写（默认就是可写的）
replica-read-only yes  # 可以改为no，允许写入
```

#### 5.3.3 重启Redis服务
```bash
# 重启Redis服务以应用新配置
systemctl restart redis

# 检查服务状态
systemctl status redis
```

### 5.4 应用连接配置更新（一般不会到这步，除非主节点恢复不了了紧急情况使用）

#### 5.4.1 更新应用配置
通知所有应用服务将Redis连接地址从原主节点IP（172.50.1.24）改为新的主节点IP（172.50.1.25）。

#### 5.4.2 验证服务可用性
```bash
# 在新主节点上测试基本操作
redis-cli -h 172.50.1.25 -a xxxxxxxxx

# 测试读写操作
172.50.1.25:6379> set test_key "test_value"
172.50.1.25:6379> get test_key
172.50.1.25:6379> del test_key
```

### 5.5 原主节点恢复（一般不会到这步，除非主节点恢复不了了紧急情况使用）

#### 5.5.1 原主节点修复后重新加入
当原主节点（172.50.1.24）修复完成后，可以将其配置为新的从节点加入集群。

##### 5.5.1.1 修改原主节点配置
```bash
# 备份原配置文件
cp /etc/redis/redis_master.conf /etc/redis/redis_master.conf.backup

# 修改配置文件，改为从节点配置
vim /etc/redis/redis_master.conf
```

修改内容：
```bash
# 添加主从配置
replicaof 172.50.1.25 6379
masterauth xxxxxxxxx

# 确保只读模式
replica-read-only yes
```

##### 5.5.1.2 重启原主节点服务
```bash
# 重启Redis服务
systemctl restart redis

# 检查主从状态
redis-cli -h 172.50.1.24 -a xxxxxxxxx info replication
```

### 5.6 数据备份与恢复

#### 5.6.1 定期数据备份
创建备份脚本：

```bash
# 创建备份目录
mkdir -p /data/redis/backup

# 创建备份脚本
vim /usr/local/bin/redis_backup.sh
```

```bash
#!/bin/bash
# Redis数据备份脚本

# 配置参数(主从注意区别IP和密码)
REDIS_HOST="172.50.1.25"
REDIS_PORT="6379"
REDIS_PASSWORD="xxxxxxxxx"
BACKUP_DIR="/data/redis/backup"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 执行备份
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD BGSAVE

# 等待备份完成
sleep 5

# 复制备份文件
cp /data/redis/dump.rdb $BACKUP_DIR/dump_$DATE.rdb
cp /data/redis/appendonly.aof $BACKUP_DIR/appendonly_$DATE.aof

# 清理7天前的备份
find $BACKUP_DIR -name "*.rdb" -mtime +7 -delete
find $BACKUP_DIR -name "*.aof" -mtime +7 -delete

echo "Redis backup completed at $DATE"
```

设置定时任务：
```bash
# 添加执行权限
chmod +x /usr/local/bin/redis_backup.sh

# 添加到crontab（每天凌晨2点备份）
echo "0 2 * * * /usr/local/bin/redis_backup.sh" | crontab -
```

#### 5.6.2 数据恢复

##### 5.6.2.1 从备份恢复数据
```bash
# 停止Redis服务
systemctl stop redis

# 备份当前数据
cp /data/redis/dump.rdb /data/redis/dump.rdb.backup.$(date +%Y%m%d_%H%M%S)

# 恢复备份数据
cp /data/redis/backup/dump_20240101_020000.rdb /data/redis/dump.rdb

# 启动Redis服务
systemctl start redis

# 验证数据
redis-cli -h 172.50.1.25 -a xxxxxxxxx keys "*"
```

### 5.7 故障转移脚本（正式环境手动调用）

创建自动化故障转移脚本：

```bash
# 创建故障转移脚本
vim /usr/local/bin/redis_failover.sh
```

```bash
#!/bin/bash
# Redis主从故障转移脚本 - 企业微信通知版

# 配置参数
MASTER_IP="172.50.1.24"
SLAVE_IP="172.50.1.25"
MASTER_PASSWORD="xxxxxxxxx"
SLAVE_PASSWORD="xxxxxxxxx"
WX_KEY="ebc925fe-4279-4716-a7d7-96d0ba331f26"
WEBHOOK_URL="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=${WX_KEY}"

# 发送企业微信消息函数
send_wechat_alert() {
    local message="$1"
    curl -H "Content-Type: application/json" \
         -d "{\"msgtype\":\"text\",\"text\":{\"content\":\"$message\"}}" \
         "$WEBHOOK_URL" >/dev/null 2>&1
}

# 检查主节点状态
if redis-cli -h $MASTER_IP -a $MASTER_PASSWORD ping &>/dev/null; then
    # 主节点正常，静默退出
    exit 0
fi

# 主节点不可用，开始故障转移
# 检查从节点状态
if ! redis-cli -h $SLAVE_IP -a $SLAVE_PASSWORD ping &>/dev/null; then
    send_wechat_alert "🚨 Redis故障转移失败\n主节点 $MASTER_IP 和从节点 $SLAVE_IP 均不可用，无法进行故障转移"
    exit 1
fi

# 执行故障转移
redis-cli -h $SLAVE_IP -a $SLAVE_PASSWORD SLAVEOF NO ONE

# 验证故障转移结果
if redis-cli -h $SLAVE_IP -a $SLAVE_PASSWORD info replication | grep -q "role:master"; then
    send_wechat_alert "✅ Redis故障转移成功\n主节点 $MASTER_IP 已故障，从节点 $SLAVE_IP 已成功提升为新的主节点，请及时更新应用配置"
else
    send_wechat_alert "❌ Redis故障转移失败\n尝试将从节点 $SLAVE_IP 提升为主节点失败，请手动处理"
    exit 1
fi
```

设置脚本权限：
```bash
chmod +x /usr/local/bin/redis_failover.sh
```

### 5.8 监控与告警

#### 5.8.1 创建监控脚本
```bash
# 创建监控脚本
vim /usr/local/bin/redis_monitor.sh
```

```bash
#!/bin/bash
# Redis主从监控脚本

# 配置参数 - 请根据实际情况修改
MASTER_IP="172.50.1.24"
SLAVE_IP="172.50.1.25"
MASTER_PASSWORD="xxxxxxxxx"
SLAVE_PASSWORD="xxxxxxxxx"
WX_KEY="ebc925fe-4279-4716-a7d7-96d0ba331f26"
WEBHOOK_URL="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=${WX_KEY}"

# 状态文件路径
STATE_DIR="/tmp/redis_monitor"
STATE_FILE="$STATE_DIR/alert_state"
DEDUP_HOURS=12
DEDUP_SECONDS=$((DEDUP_HOURS * 3600))

# 创建状态目录
mkdir -p "$STATE_DIR"

# 发送企业微信消息函数
send_wechat_alert() {
    local message="$1"
    local alert_type="$2"
    local current_time=$(date +%s)
    
    # 检查是否应该发送告警
    if should_send_alert "$alert_type" "$current_time"; then
        curl -H "Content-Type: application/json" \
             -d "{\"msgtype\":\"text\",\"text\":{\"content\":\"$message\"}}" \
             "$WEBHOOK_URL" >/dev/null 2>&1
        
        # 更新发送时间
        update_alert_time "$alert_type" "$current_time"
    fi
}

# 检查是否应该发送告警
should_send_alert() {
    local alert_type="$1"
    local current_time="$2"
    
    # 如果状态文件不存在，允许发送
    if [ ! -f "$STATE_FILE" ]; then
        return 0
    fi
    
    # 获取上次发送时间
    local last_time=$(grep "^$alert_type:" "$STATE_FILE" | cut -d: -f2)
    
    # 如果该类型告警从未发送过，允许发送
    if [ -z "$last_time" ]; then
        return 0
    fi
    
    # 计算时间差
    local time_diff=$((current_time - last_time))
    
    # 如果时间差大于12小时，允许发送
    if [ $time_diff -ge $DEDUP_SECONDS ]; then
        return 0
    fi
    
    return 1
}

# 更新告警发送时间
update_alert_time() {
    local alert_type="$1"
    local current_time="$2"
    
    # 如果文件不存在，创建文件
    if [ ! -f "$STATE_FILE" ]; then
        echo "$alert_type:$current_time" > "$STATE_FILE"
        return
    fi
    
    # 检查该类型告警是否已存在
    if grep -q "^$alert_type:" "$STATE_FILE"; then
        # 更新已存在的记录
        sed -i "s/^$alert_type:.*/$alert_type:$current_time/" "$STATE_FILE"
    else
        # 添加新记录
        echo "$alert_type:$current_time" >> "$STATE_FILE"
    fi
}

# 清理过期状态（可选，保留7天前的记录）
cleanup_old_states() {
    local current_time=$(date +%s)
    local expire_seconds=$((7 * 24 * 3600))
    
    if [ -f "$STATE_FILE" ]; then
        local temp_file=$(mktemp)
        while IFS=: read -r alert_type timestamp; do
            local time_diff=$((current_time - timestamp))
            if [ $time_diff -lt $expire_seconds ]; then
                echo "$alert_type:$timestamp" >> "$temp_file"
            fi
        done < "$STATE_FILE"
        mv "$temp_file" "$STATE_FILE"
    fi
}

# 主监控逻辑
main() {
    # 清理过期状态
    cleanup_old_states
    
    # 检查主节点状态
    if ! /usr/local/bin/redis-cli -h $MASTER_IP -a $MASTER_PASSWORD ping &>/dev/null; then
        # 主节点异常
        if /usr/local/bin/redis-cli -h $SLAVE_IP -a $SLAVE_PASSWORD ping &>/dev/null; then
            send_wechat_alert "⚠️ Redis主节点故障告警\n主节点 $MASTER_IP 不可用，从节点 $SLAVE_IP 正常，请及时处理故障转移" "master_down"
        else
            send_wechat_alert "🚨 Redis集群故障告警\n主节点 $MASTER_IP 和从节点 $SLAVE_IP 均不可用，请立即处理！" "both_down"
        fi
    else
        # 主节点正常，检查从节点状态
        if ! /usr/local/bin/redis-cli -h $SLAVE_IP -a $SLAVE_PASSWORD ping &>/dev/null; then
            send_wechat_alert "⚠️ Redis从节点故障告警\n主节点 $MASTER_IP 正常，但从节点 $SLAVE_IP 不可用，请检查从节点状态" "slave_down"
        else
            # 检查主从同步状态
            slave_count=$(/usr/local/bin/redis-cli -h $MASTER_IP -a $MASTER_PASSWORD info replication | grep "connected_slaves" | cut -d: -f2 | tr -d '\r')
            if [ "$slave_count" != "1" ]; then
                send_wechat_alert "⚠️ Redis主从同步异常\n主节点 $MASTER_IP 正常，但从节点同步异常，连接从节点数量：$slave_count" "sync_error"
            fi
        fi
    fi
}

# 执行主函数
main
```

#### 5.8.2 设置定时监控
使用已创建的企业微信监控脚本（支持12小时去重功能）：

```bash
# 复制脚本到系统目录
cp /usr/local/bin/redis_monitor_wechat.sh /usr/local/bin/redis_monitor.sh
cp /usr/local/bin/redis_failover_wechat.sh /usr/local/bin/redis_failover.sh

# 添加执行权限
chmod +x /usr/local/bin/redis_monitor.sh
chmod +x /usr/local/bin/redis_failover.sh

# 每5分钟检查一次（支持12小时去重，相同类型告警12小时内只发送一次）
echo "*/5 * * * * /usr/local/bin/redis_monitor.sh" | crontab -
```

#### 5.8.3 企业微信配置说明
1. **修改Webhook Key**：将脚本中的`WX_KEY`替换为你的实际企业微信群机器人key
2. **测试消息推送**：
   ```bash
   # 测试监控脚本
   /usr/local/bin/redis_monitor.sh
   
   # 测试故障转移脚本
   /usr/local/bin/redis_failover.sh
   ```
3. **12小时去重功能**：
   - 相同类型的告警12小时内只发送一次
   - 状态文件保存在`/tmp/redis_monitor/alert_state`
   - 支持4种告警类型独立去重：master_down、both_down、slave_down、sync_error
4. **手动重置告警**：如需立即重新发送告警，可删除状态文件
   ```bash
   rm -f /tmp/redis_monitor/alert_state
   ```
5. **脚本位置**：监控脚本已放置在`script/redis_monitor.sh`和`script/redis_failover.sh`，可直接使用

### 5.9 注意事项

1. **数据一致性**：故障转移后，原主节点上的未同步数据可能会丢失
2. **客户端重连**：应用需要支持Redis连接重试和故障转移
3. **密码安全**：确保密码强度足够，定期更换密码
4. **监控告警**：建议配合监控系统（如Prometheus）实现自动告警
5. **备份策略**：定期执行数据备份，验证备份可用性
6. **测试演练**：定期进行故障转移演练，确保流程可靠

### 5.10 故障转移检查清单

- [ ] 确认主节点确实不可用
- [ ] 确认从节点数据是最新的
- [ ] 执行从节点升主操作
- [ ] 更新应用配置
- [ ] 验证服务可用性
- [ ] 通知相关人员
- [ ] 记录故障转移过程
- [ ] 安排原主节点修复
- [ ] 测试原主节点重新加入集群
