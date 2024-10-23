%{
  title: "华为GuassForMySQL迁移步骤",
  description: "",
  keywords: []
}
---

### 注意事项
 - 目标库账号、数据库需提前申请创建；
 - 事件需手动迁移；
 - 源实例修改最大连接事件参数 `wait_timeout`；
 - 实时同步期间，源库不要做DDL语句。

### 迁移迁准备
所需工具
 - 阿里云源实例RDS for MySQL
 - 华为云目标实例 GaussDB for MySQL
 - 阿里云网关DG
 - 阿里云DTS
 - ~~华为云DRS~~
 - 网络白名单添加
 - 阿里云源实例RDS参数调整

### 实例初始化(华为云GaussDB)
依然走资产平台线上申请，由佳敏等统一创建
 - 实例申请：统一申请华为GaussDB for MySQL , 不使用华为云RDS，分好产品线，原则上每个产品线一个实例，如有性能需求较大的可单独申请实例
 - 安全组选择： 测试环境单独一个，正式环境按产品线分不同安全组
 - 实例自定义参数调整：参考 [共享文档](https://doc.weixin.qq.com/sheet/e2_AKsAFwYUAH8OLtIkczTT0q1yt1Tum?scode=AA8AXgfeABAgdYi40HAJcAFwYUAH8)，为保障迁移时源和目标参数一致性，需要手动调整华为云GaussDB参数：
 > `INNODB_STRICT_MODE` 为 `OFF`，迁移后是否可以将此参数修改回来

 > `explicit_defaults_for_timestamp` 为 `OFF`
 - 备份恢复策略制定：参考同上
 - 白名单添加：直接加入安全组，无需单独给实例添加白名单
### 项目资源初始化(华为元GaussDB)
依然走资产平台线上申请，由佳敏等统一创建
 - 数据库创建：注意备注，<font color=orange>因项目账号没有建库权限，必须提前申请建库</font>；
 - 账号创建：注意备注，账号权限范围需要自己手动选择，(待出具具体选项)
 - 阿里云DMS工具注册，本期会用企业网关方式将华为云内网接入阿里云VPC，使其可以互通，数据库管理工具依然统一使用阿里DMS
 - DMS资源访问权限分配
### 网络连接
 - 阿里云搭建与华为云内网互通的网关: 已搭建好的网关名称:<font color=orange>dg-qmv45by5l8xf403w</font> (华为云_DG)
 - 目标实例华为云GaussDB所属安全组添加阿里云网关白名单
 - 源实例阿里云RDS添加DTS网段白名单
### 源实例参数调整
 - 初始化的时候，大表需要占用长连接，需要修改源实例参数 `wait_timeout`为`86400`， 初始化完成之后可以调整回来
<details>
  <summary>华为DRS建立-实时同步管理方式(初始化未能完成，已放弃)</summary>
  
 - 创建同步任务
 - 网络白名单添加
 - 源库及目标库添加
 - 账号：源实例使用项目专用账号即可，目标实例，需要提前创建数据库、账号
 - 设置同步
 - 数据加工
 - 预检查
 - 任务确认
 - 开启同步

华为云DRS数据同步错误：

![](https://imgwong.oss-cn-hangzhou.aliyuncs.com/202212061008610.png)

> 1.华为DRS数据同步时，现在观察不会分片，单表直接全部抽取，对源实例性能影响较大，初始化尽量选择非业务繁忙时间；
  
> 2.同步对象中如果存在包含longtext或longblob类型字段的表，建议创建大规格及以上规格的DRS任务进行同步；
  
> 3.无主键表同步性能低于主键表，同步性能存在延时增大的可能,不能保证无主键表的数据一致性。建议将无主键表修改为主键表;
  
> 4.~~警告详情：源数据库用户在MySQL系统库权限不足，如果需要迁移用户，则需要mysql.user表的select权限，而在8.0以下，如果需要迁移函数、存储过程，则需要mysql.proc表的select权限。~~
  
> 5.事件需待同步链路结束后，再同步过去，正在进行的链路目标库是看不到源实例的事件的。
  
</details>

### 阿里云DTS实时迁移任务创建

使用阿里云lunz账号下子账号，创建DTS<font color=red>数据同步</font>任务，如源实例不在此账号下，可协调SRE获取跨账号选择源实例的实例Id和角色相关信息。
关于连接地址选择：数据同步时需确认使用华为云网关的<font color=red>读写内网地址</font>。后期给应用连接，使用代理<font color=red>读写分离地址</font>：

![地址确认](https://imgwong.oss-cn-hangzhou.aliyuncs.com/202212121106192.png)

 - 迁移任务创建，建议选择medium规格(可按项目数据量大小按需调整)，按量付费(一般提前一周进行)。
 - 选择华为云网关页面：

![迁移任务创建选网关](https://imgwong.oss-cn-hangzhou.aliyuncs.com/202212060842171.png)

 - 选择整库迁移后，其他参数默认。(DTS不能迁移事件，事件需迁移项目上线后，选择合适事件手动迁移并确保开启)
  
![迁移对象选择](https://imgwong.oss-cn-hangzhou.aliyuncs.com/202212060916017.png)
 
两张数据初始化时各实例性能参数对比，注意数据初始化一定要在非业务繁忙期，建议在周末的20:00后进行。

![源实例性能趋势](https://imgwong.oss-cn-hangzhou.aliyuncs.com/202212060829347.png)

![目标实例性能趋势](https://imgwong.oss-cn-hangzhou.aliyuncs.com/202212060827078.png)

 - 迁移中遇到的错误：此问题需按上面步骤，修改源实例RDS参数加长 `wait_timeout` 。

![DTS迁移错误1](https://imgwong.oss-cn-hangzhou.aliyuncs.com/202212060822295.png)

 - 初始化对象报错，需提前创建所迁移目标数据库：

![目标库未创建报错](https://imgwong.oss-cn-hangzhou.aliyuncs.com/202212121131637.png)

 - 数据迁移期间，<font color=red>不允许源实例有无主键表创建、`CREATE TABLE AS` 语句，忍一忍直接就别动源库结构了</font>

![DTS链路报错](https://imgwong.oss-cn-hangzhou.aliyuncs.com/202212071533052.png)

## 正式环境迁移模拟，性能测试
### 数据同步

步骤如上介绍。

### 测试性能
 - 在源库筛选慢SQL
 - 在华为云数据库测试慢SQL执行速度
 - 查看执行计划区别
 - 是否有执行时间断崖式下降的SQL
 - 将常用的一些语句，使用 [mysqlslap](https://dev.mysql.com/doc/refman/8.0/en/mysqlslap.html) 压测与源实例对比，也可以使用行业内通用压测工具，[Sysbench](https://help.aliyun.com/document_detail/405017.html) 测试，这个工具不能指定压测SQL语句。

附上GFS比较慢的几条SQL对比 [GFS慢SQL执行时间对比](https://doc.weixin.qq.com/sheet/e3_AJcAFwYUAH8D0SNKfs4Qmu6K6C10A?scode=AA8AXgfeABA40c0AxFAJcAFwYUAH8)

## 测试环境迁移

### 数据同步
 - 提前3天将数据同步链路建立，确保数据同步完全、同步延迟在可控范围内；
 - 手动迁移事件，并停用所有事件，记录源实例哪些事件需要开启(上线后需要手动开启)；
 - 切换当晚，首先停掉应用；
 - 停用阿里测试库账号；
 - 开启应用；
 - 开启所需事件，如项目正常运行，停掉RDS同步链路；
  > 注意：需要保障事件运行，有同步链路就在源库执行，无同步链路就在目标库执行；
  > 切换期间不要漏掉每小时的事件如果迁移跨天需确认迁移期间内需要执行的事件。
 - 7天后无数据问题，删除阿里RDS测试环境数据库；

## 正式环境迁移
 - 提前7天将数据同步链路建立，确保数据同步完全、同步延迟在可控范围内；
 - 手动迁移事件，并停用所有事件，记录源实例哪些事件需要开启(上线后需要手动开启)；
 - 切换当晚，首先<font color = red>停掉应用</font>；
 - <font color = red>停用阿里应用账号</font>；
 - <font color = red>开启应用</font>；
 - <font color = red>开启所需事件</font>，如项目正常运行，停掉RDS同步链路；
  > 注意：需要保障事件运行，有同步链路就在源库执行，无同步链路就在目标库执行；
  > 切换期间不要漏掉每小时的事件如果迁移跨天需确认迁移期间内需要执行的事件。
 - 测试应用性能；
 - 7天后数据无问题，停掉DRS同步链路；
 - 删除阿里RDS数据库；