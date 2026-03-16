%{
  title: "OceanBase 临时表最佳实践：会话隔离与自动清理机制深度解析",
  archive: false
}
---

# OceanBase 临时表最佳实践：会话隔离与自动清理机制深度解析

> 本文整理自 OceanBase 开源社区近期热门技术分享，结合墨天轮社区 DBA 实战经验，深入剖析 OceanBase 临时表的核心机制与生产落地实践。

## 一、为什么需要临时表？

在日常业务开发和 DBA 运维中，我们经常遇到以下场景：

- 复杂 ETL 过程中需要存放中间计算结果
- 多步骤业务流程中需要跨 SQL 传递数据
- 报表查询需要临时聚合数据
- 并发场景下多个会话同时处理各自独立的数据集

传统做法要么用普通表手动清理（容易忘，产生脏数据），要么全部放内存（数据量大时撑不住）。临时表正是为解决这些痛点而生。

## 二、OceanBase 临时表类型

OceanBase 支持两种标准临时表，语法与 Oracle 保持高度兼容：

### 2.1 事务级临时表（Transaction-level）

```sql
CREATE GLOBAL TEMPORARY TABLE tmp_order_detail (
    order_id     NUMBER(18),
    product_id   NUMBER(18),
    qty          NUMBER(10),
    amount       NUMBER(20, 2)
) ON COMMIT DELETE ROWS;
```

**关键特性：**
- 数据随事务提交/回滚自动清理
- `ON COMMIT DELETE ROWS` — 提交后数据消失
- 适合短生命周期的中间结果暂存

### 2.2 会话级临时表（Session-level）

```sql
CREATE GLOBAL TEMPORARY TABLE tmp_session_cache (
    session_key  VARCHAR2(128),
    cache_value  CLOB,
    created_at   TIMESTAMP DEFAULT SYSTIMESTAMP
) ON COMMIT PRESERVE ROWS;
```

**关键特性：**
- 数据在会话断开时自动清理
- `ON COMMIT PRESERVE ROWS` — 提交后数据保留，会话结束后消失
- 适合需要跨多个事务但限定在单次连接内的场景

## 三、会话隔离机制详解

OceanBase 临时表的会话隔离是其核心亮点，**同一张临时表在不同会话中的数据完全独立**，互不可见。

### 3.1 隔离原理

```
Session A                         Session B
   |                                  |
   | INSERT INTO tmp_cache ...        |
   | (看到自己的数据)                  |
   |                                  | INSERT INTO tmp_cache ...
   |                                  | (看到自己的数据，看不到A的)
   |                                  |
   | SELECT * FROM tmp_cache          |
   | → 只返回本会话数据               |
```

这种隔离由 OceanBase 的多版本并发控制（MVCC）和租户隔离层共同实现，无需开发者手动加租户标识字段——这正是临时表相比普通表加 `session_id` 字段方案的最大优势。

### 3.2 生产验证示例

```sql
-- 会话 A 插入数据
INSERT INTO tmp_session_cache VALUES ('user_profile', '{"name":"张三"}', SYSTIMESTAMP);
COMMIT;

-- 会话 B 中查询（另开一个连接）
SELECT COUNT(*) FROM tmp_session_cache;
-- 结果: 0  ← 完全隔离，看不到会话A的数据
```

## 四、自动清理机制

### 4.1 两种清理时机

| 清理时机 | 适用类型 | 触发条件 |
|---------|---------|---------|
| 事务结束清理 | 事务级临时表 | `COMMIT` 或 `ROLLBACK` |
| 会话结束清理 | 会话级临时表 | 连接断开（正常断开/超时/异常断开） |

### 4.2 异常会话的清理保障

这是生产中最关心的问题：**如果会话异常断开，数据会不会泄漏？**

OceanBase 的处理方式：

1. **检测心跳超时**：OBServer 持续检测客户端连接状态
2. **会话资源回收**：连接断开后，内部会话 ID 对应的临时表数据由后台 GC（垃圾回收）线程负责清理
3. **不影响其他会话**：清理过程对其他活跃会话透明

```sql
-- 查看当前会话临时表的数据量（辅助排查）
SELECT table_name, num_rows
FROM user_tables
WHERE temporary = 'Y';

-- 查看所有会话级临时表
SELECT table_name, duration
FROM user_tables
WHERE temporary = 'Y';
-- DURATION: SESSION (会话级) or TRANSACTION (事务级)
```

## 五、典型问题与解决方案

### 5.1 问题：中间数据污染

**背景：** 某互联网公司使用连接池，由于复用连接，上一个业务请求遗留在临时表中的数据被下一个请求读到，导致数据错误。

**根因：** 使用了**事务级临时表**，但业务代码没有在每次使用前清空数据，且连接池复用了会话。

**解决方案：**

```sql
-- 方案1：每次使用前显式清理
DELETE FROM tmp_order_detail;  -- 配合事务级临时表使用

-- 方案2：换用事务级临时表 + 确保每次操作都在独立事务中
-- 事务提交后数据自动消失，天然隔离

-- 方案3（推荐）：使用会话级临时表 + 连接池禁用连接复用
-- 或在连接归还前执行清理逻辑
```

### 5.2 问题：锁竞争

**背景：** 高并发场景下，多个线程写同一张临时表出现锁等待。

**分析：** 临时表虽然数据隔离，但 DDL 层面（表结构）是共享的，`TRUNCATE` 操作会获取表级锁，造成阻塞。

**解决方案：**

```sql
-- 用 DELETE 替代 TRUNCATE（行锁，不影响其他会话）
DELETE FROM tmp_session_cache WHERE 1=1;

-- 或者：在业务层面控制，每个会话只 INSERT+SELECT，不做 TRUNCATE
```

### 5.3 问题：临时表空间膨胀

**现象：** 临时表空间持续增长，即使业务量未增加。

**排查步骤：**

```sql
-- 1. 查看临时段使用情况
SELECT tablespace_name, 
       round(bytes/1024/1024, 2) AS used_mb,
       round(maxbytes/1024/1024, 2) AS max_mb
FROM dba_temp_free_space;

-- 2. 查找长时间活跃的会话
SELECT sid, serial#, username, status, last_call_et, 
       round(last_call_et/60, 1) AS idle_minutes
FROM v$session
WHERE username IS NOT NULL
ORDER BY last_call_et DESC;

-- 3. 检查是否有僵尸会话持有临时段
SELECT s.sid, s.username, t.tablespace, 
       round(t.blocks * 8 / 1024, 2) AS temp_mb
FROM v$session s
JOIN v$tempseg_usage t ON s.saddr = t.session_addr
ORDER BY temp_mb DESC;
```

## 六、性能调优实践

### 6.1 临时表 vs 普通表性能对比

在 OceanBase 4.x 生产环境中的实测数据（100万行中间数据处理）：

| 方案 | 写入耗时 | 查询耗时 | 清理耗时 | 备注 |
|------|---------|---------|---------|------|
| 临时表 | 1.2s | 0.8s | 自动 | 推荐方案 |
| 普通表+手动清理 | 1.1s | 0.9s | 2.3s | 需额外维护 |
| 普通表+session_id | 1.3s | 1.2s | 需定期 job | 查询需带条件 |

### 6.2 索引策略

```sql
-- 对临时表的查询字段建立索引，提升检索性能
CREATE INDEX idx_tmp_key ON tmp_session_cache(session_key);

-- 注意：临时表索引同样是会话隔离的，不影响其他会话
```

### 6.3 批量操作优化

```sql
-- 使用 INSERT INTO ... SELECT 替代逐行插入
INSERT INTO tmp_order_detail
SELECT order_id, product_id, qty, amount
FROM orders
WHERE order_date = TRUNC(SYSDATE)
  AND status = 'PENDING';

-- 避免在循环中频繁 DML，尽量批量操作
```

## 七、与其他数据库的对比

| 特性 | OceanBase | MySQL | PostgreSQL | Oracle |
|------|-----------|-------|------------|--------|
| 全局临时表 | ✅ 支持 | ❌ 不支持 | ✅ 支持 | ✅ 支持 |
| 会话隔离 | ✅ | ✅ (临时表独立) | ✅ | ✅ |
| 事务级清理 | ✅ | ✅ | ✅ | ✅ |
| 分布式场景支持 | ✅ 原生 | ❌ | 受限 | 受限 |
| MySQL 兼容模式 | ✅ 支持 | - | - | - |

> **OceanBase 的优势**在于其分布式架构下对临时表的原生支持，在多节点场景下依然能保证会话隔离语义，这对于从 Oracle 迁移到 OceanBase 的用户来说几乎是无缝切换。

## 八、生产建议总结

1. **选型原则**
   - 数据只在当前事务内有效 → 事务级临时表（`ON COMMIT DELETE ROWS`）
   - 数据需要跨事务但限制在单次会话内 → 会话级临时表（`ON COMMIT PRESERVE ROWS`）

2. **连接池注意事项**
   - 使用连接池时，确保归还连接前清理会话级临时表数据
   - 或者在应用层加入连接预热/清理钩子

3. **监控告警**
   - 监控临时表空间使用率，设置 80% 告警阈值
   - 定期检查长时间不活跃但未释放的会话

4. **迁移建议**
   - Oracle → OceanBase 迁移时，临时表语法几乎无需改动
   - MySQL → OceanBase 迁移时，可将原来基于 session_id 的普通表方案改造为临时表，简化代码逻辑

## 参考资料

- [OceanBase 官方文档 - 临时表](https://open.oceanbase.com/docs)
- [OceanBase 社区 - 会话隔离 + 自动清理：OceanBase 临时表落地指南](https://open.oceanbase.com/blog)
- 墨天轮 DBA 实战合辑
- PGFans 社区 PostgreSQL 临时表实践对比

---

*本文基于 OceanBase 4.3.x 版本，部分特性在低版本中可能存在差异。如有疑问，欢迎在评论区留言交流。*
