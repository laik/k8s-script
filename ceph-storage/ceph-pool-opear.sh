Ceph Pool操作总结
一个ceph集群可以有多个pool，每个pool是逻辑上的隔离单位，不同的pool可以有完全不一样的数据处理方式，比如Replica Size（副本数）、Placement Groups、CRUSH Rules、快照、所属者等。

打印pool列表
ceph osd lspools

创建pool
通常在创建pool之前，需要覆盖默认的pg_num，官方推荐：

若少于5个OSD， 设置pg_num为128。

5~10个OSD，设置pg_num为512。
10~50个OSD，设置pg_num为4096。

超过50个OSD，可以参考pgcalc计算。
本文的测试环境只有2个OSD，因此设置pg_num为128。

osd pool default pg num = 128
osd pool default pgp num = 128

创建pool语法:

ceph osd pool create {pool-name} {pg-num} [{pgp-num}] [replicated] \
     [crush-ruleset-name] [expected-num-objects]
ceph osd pool create {pool-name} {pg-num}  {pgp-num}   erasure \
     [erasure-code-profile] [crush-ruleset-name] [expected_num_objects]
创建一个test-pool，pg_num为128：

ceph osd pool create test-pool 128

设置pool配额
支持object个数配额以及容量大小配额。

设置允许最大object数量为100：

ceph osd pool set-quota test-pool max_objects 100
设置允许容量限制为10GB:

ceph osd pool set-quota test-pool max_bytes $((10 * 1024 * 1024 * 1024))
取消配额限制只需要把对应值设为0即可。

重命名pool
ceph osd pool rename test-pool test-pool-new
删除pool
删除一个pool会同时清空pool的所有数据，因此非常危险。(和rm -rf /类似）。因此删除pool时ceph要求必须输入两次pool名称，同时加上--yes-i-really-really-mean-it选项。

ceph osd pool delete test-pool test-pool  --yes-i-really-really-mean-it
查看pool状态信息
rados df
创建快照
ceph支持对整个pool创建快照（和Openstack Cinder一致性组区别？），作用于这个pool的所有对象。但注意ceph有两种pool模式：

Pool Snapshot，我们即将使用的模式。创建一个新的pool时，默认也是这种模式。
Self Managed Snapsoht，用户管理的snapshot，这个用户指的是librbd，也就是说，如果在pool创建了rbd实例就自动转化为这种模式。
这两种模式是相互排斥，只能使用其中一个。因此，如果pool中曾经创建了rbd对象（即使当前删除了所有的image实例）就不能再对这个pool做快照了。反之，如果对一个pool做了快照，就不能创建rbd image了。

ceph osd pool mksnap test-pool test-pool-snapshot
删除快照
ceph osd pool rmsnap test-pool test-pool-snapshot
设置pool
通过以下语法设置pool的元数据：

ceph osd pool set {pool-name} {key} {value}
比如设置pool的冗余副本数量为3:

ceph osd pool set test-pool size 3
其他配置项参考文档。

通过get操作能够获取pool的配置值,比如获取当前pg_num：

ceph osd pool get test-pool pg_num
获取当前副本数:

ceph osd pool get test-pool size