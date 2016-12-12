# Kubernetes 1.4 高级课程

###### kissingwolf@gmail.com

[TOC]

## Kubernetes 资源管理

Kubernetes 资源管理包括Compute Resources（计算资源）、Limit Range（限制范围）、QoS（服务质量控制）和 Resource Quota (资源配额)等方面。

### Compute Resources 计算资源管理

#### 资源分类说明

Compute Resources 计算资源配置分为两种，Resource Requrests (资源请求)和Resource Limits (资源限制)。

* Resource Requrests (资源请求)，简称Requests ，表示希望分配给容器的最低保证其运行的资源量。
* Resource Limits (资源限制)，简称Limits ，表示最多分配给容器运行的资源量上限。

在Kubernetes 中，计算资源分为CPU和Memory（内存）两种。这两种资源都有其基本的分配单位：

* CPU 基本分配单位为Cores（核心数），一个Core（核心）标记为单位 “1” ，CPU资源最多支持三位小数分配，比如1.5 代表分配1.5个核心。另外可以使用m为单位代表1/1000的核心，比如100m代表0.1 核心。官方推荐使用100m的形式代表0.1 cpu core。
* Memory（内存）基本分配单位为Bytes（字节数），Memory（内存）以整数加上容量单位来表示，十进制单位K、M、G、T、P、E，二进制单位Ki、Mi、Gi、Ti、Pi、Ei。需要注意m和M不是同一单位，m表示千分之一单位（mili unit），M表示十进制1000。

在Pod配置中，计算资源配置项有四个:

* spec.container[].resources.requests.cpu
* spec.container[].resources.requests.memory
* spec.container[].resources.limits.cpu
* spec.container[].resources.limits.memory

四个配置项分别对应容器中的CPU和Memory（内存）的Requests和Limits。

其特点如下：

* Requests和Limits都是可选配置，如果在创建Pod时没有指定，则继承Cluster配置。
* 如果仅仅设置Limits而没有设置Requests，则Requests等于Limits。
* 任何情况下Limits应该大于等于Requests。
* Pod中的容器Requests是启动容器的最小资源需求，如果Node无法满足创建Pod容器的Requests，则该Node上无法创建该Pod容器。

#### 配置资源例子

我们来看一个Pod配置的例子，创建一个配置文件pod-resource.yaml，内容如下：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-resource
spec:
  containers:
  - name: nginx
    image: nginx:latest
    imagePullPolicy: IfNotPresent
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

我们可以通过kubectl create 创建Pod ：

```shell
[root@master0 ~]# kubectl create -f pod-resource.yaml
pod "test-pod-resource" created
```

可以通过kubectl describe 查看创建Pod的具体信息：

```shell
[root@master0 ~]# kubectl describe pod test-pod-resource
Name:		test-pod-resource
Namespace:	default
Node:		nodec0.example.com/172.25.0.13
Start Time:	Mon, 12 Dec 2016 14:46:53 +0800
Labels:		<none>
Status:		Running
IP:		10.38.0.12
Controllers:	<none>
Containers:
  nginx:
    Container ID:	docker://afd8950ec7322705b1e7114dc13d982ed220ecbe226ce92192e54967a0008144
    Image:		nginx:latest
    Image ID:		docker://sha256:abf312888d132e461c61484457ee9fd0125d666672e22f972f3b8c9a0ed3f0a1
    Port:
    Limits:
      cpu:	500m
      memory:	128Mi
    Requests:
      cpu:		250m
      memory:		64Mi
    State:		Running
      Started:		Mon, 12 Dec 2016 14:46:57 +0800
    Ready:		True
    Restart Count:	0
    Volume Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-k5azo (ro)
    Environment Variables:	<none>
Conditions:
  Type		Status
  Initialized 	True
  Ready 	True
  PodScheduled 	True
Volumes:
  default-token-k5azo:
    Type:	Secret (a volume populated by a Secret)
    SecretName:	default-token-k5azo
QoS Class:	Burstable
Tolerations:	<none>
Events:
  FirstSeen	LastSeen	Count	From				SubobjectPath		Type		Reason		Message
  ---------	--------	-----	----				-------------		--------	------		-------
  1m		1m		1	{default-scheduler }			Normal		Scheduled	Successfully assigned test-pod-resource to nodec0.example.com
  1m		1m		1	{kubelet nodec0.example.com}	spec.containers{nginx}	Normal		Pulled		Container image "nginx:latest" already present on machine
  1m		1m		1	{kubelet nodec0.example.com}	spec.containers{nginx}	Normal		Created		Created container with docker id afd8950ec732; Security:[seccomp=unconfined]
  1m		1m		1	{kubelet nodec0.example.com}	spec.containers{nginx}	Normal		Started		Started container with docker id afd8950ec732
```

可以看到如下有用的信息：

```config
 Limits:
      cpu:	500m
      memory:	128Mi
 Requests:
      cpu:		250m
      memory:		64Mi
```

代表此Pod中nginx容器最低需要64MiB的内存和0.25 CPU Core，最大使用资源为128 MiB的内存和0.5 CPU Core。

#### 资源分配过量例子

如果Kubernetes 集群调度器在集群中找不到合适的Node节点来运行Pod，那么Pod将会处在未调度状态，直到Kubernetes集群调度器找到合适的Node节点运行Pod为止。每次Kubernetes 调度器失败都会产生一个event 事件。例如我们要创建的Pod所需资源远远超过了Node能够分配的最大资源。

我们来演示Pod资源超过Node节点资源的情况，首先确定Node节点的资源状态：

```shell
[root@master0 ~]# kubectl describe node  |grep cpu
 cpu:					2
 cpu:					2
 cpu:					2
 cpu:					2
 cpu:					2
 cpu:					2
 cpu:					2
 cpu:					2
 [root@master0 ~]# kubectl describe node  |grep memory:
 memory:				1884120Ki
 memory:				1884120Ki
 memory:				1016792Ki
 memory:				1016792Ki
 memory:				1016792Ki
 memory:				1016792Ki
 memory:				1016792Ki
 memory:				1016792Ki
```

所有Node 节点最多支持CPU Core为2 ，最多支持Memory为1016792KiB。我们只需要创建超过其中一只的资源就可以演示错误。

我们先停止之前创建的Pod test-pod-resource：

```shell
[root@master0 ~]# kubectl delete -f pod-resource.yaml
```

然后修改配置文件pod-resource.yaml ：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-resource
spec:
  containers:
  - name: nginx
    image: nginx:latest
    imagePullPolicy: IfNotPresent
    resources:
      requests:
        cpu: "3"
```

创建Pod：

```shell
[root@master0 ~]# kubectl create  -f pod-resource.yaml
pod "test-pod-resource" created
```

此Pod 会呈现pending状态

```shell
[root@master0 ~]# kubectl get pod
NAME                READY     STATUS    RESTARTS   AGE
test-pod-resource   0/1       Pending   0          32s
```

查看详细信息

```shell
[root@master0 ~]# kubectl describe pod test-pod-resource
Name:		test-pod-resource
Namespace:	default
Node:		/
Labels:		<none>
Status:		Pending
IP:
Controllers:	<none>
Containers:
  nginx:
    Image:	nginx:latest
    Port:
    Requests:
      cpu:	3
    Volume Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-k5azo (ro)
    Environment Variables:	<none>
Conditions:
  Type		Status
  PodScheduled 	False
Volumes:
  default-token-k5azo:
    Type:	Secret (a volume populated by a Secret)
    SecretName:	default-token-k5azo
QoS Class:	Burstable
Tolerations:	<none>
Events:
  FirstSeen	LastSeen	Count	From			SubobjectPath	Type		Reason			Message
  ---------	--------	-----	----			-------------	--------	------			-------

  13s	13s	1	{default-scheduler }		Warning	FailedSchedulingpod (test-pod-resource) failed to fit in any node
fit failure on node (nodea0.example.com): Insufficient cpu
fit failure on node (nodec0.example.com): Insufficient cpu
fit failure on node (nodeb0.example.com): Insufficient cpu
fit failure on node (master0.example.com): Insufficient cpu, PodToleratesNodeTaints
```

删除已创建的Pod

```shell
[root@master0 ~]#  kubectl delete -f pod-resource.yaml
pod "test-pod-resource" deleted
```

调整配置文件

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-resource
spec:
  containers:
  - name: nginx
    image: nginx:latest
    imagePullPolicy: IfNotPresent
    resources:
      requests:
        cpu: "1"
```

重新创建Pod，在可用资源框架下运行

```shell
[root@master0 ~]# kubectl create -f pod-resource.yaml
pod "test-pod-resource" created

[root@master0 ~]# kubectl get pod
NAME                READY     STATUS    RESTARTS   AGE
test-pod-resource   1/1       Running   0          7s
```

如果我们在工作环境中碰到相同的问题，我们可以采取如下解决方案：

* 添加更多的Node节点资源，横向的扩展Kubernetes 集群资源。
* 停止当前正在运行的不必要Pod，释放可用的Kubernetes 集群资源。
* 检查配置错误，重新启动Pod

如果在Pod运行过程中，Pod内的容器需求资源超过Limits分配的资源时，Pod内容器将被Kubernetes 调度器重启，以使资源被释放后重新分配。

#### 查看资源分配状态

通过kubectl describe 命令我们可以查看Node节点上资源分配的状态。

首先确认Pod运行在哪个Node节点上

```shell
[root@master0 ~]# kubectl describe pod  test-pod-resource | grep Node:
Node:		nodea0.example.com/172.25.0.11
```

然后查看Node的具体信息

```shell
[root@master0 ~]# kubectl describe node nodea0
Name:			nodea0.example.com
Labels:			beta.kubernetes.io/arch=amd64
			beta.kubernetes.io/os=linux
			kubernetes.io/hostname=nodea0.example.com
Taints:			<none>
CreationTimestamp:	Tue, 22 Nov 2016 12:49:21 +0800
Phase:
Conditions:
  Type			Status	LastHeartbeatTime			LastTransitionTime			Reason				Message
  ----			------	-----------------			------------------			------				-------
  OutOfDisk 		False 	Mon, 12 Dec 2016 16:36:39 +0800 	Fri, 25 Nov 2016 14:59:35 +0800 	KubeletHasSufficientDisk 	kubelet has sufficient disk space available
  MemoryPressure 	False 	Mon, 12 Dec 2016 16:36:39 +0800 	Tue, 22 Nov 2016 12:49:21 +0800 	KubeletHasSufficientMemory 	kubelet has sufficient memory available
  DiskPressure 		False 	Mon, 12 Dec 2016 16:36:39 +0800 	Tue, 22 Nov 2016 12:49:21 +0800 	KubeletHasNoDiskPressure 	kubelet has no disk pressure
  Ready 		True 	Mon, 12 Dec 2016 16:36:39 +0800 	Tue, 22 Nov 2016 12:49:21 +0800 	KubeletReady 			kubelet is posting ready status
Addresses:		172.25.0.11,172.25.0.11
Capacity:
 alpha.kubernetes.io/nvidia-gpu:	0
 cpu:					2
 memory:				1016792Ki
 pods:					110
Allocatable:
 alpha.kubernetes.io/nvidia-gpu:	0
 cpu:					2
 memory:				1016792Ki
 pods:					110
System Info:
 Machine ID:			ecd4a28875734de9bf2cb5e40cbf88da
 System UUID:			9E450584-DC5A-4B7C-809E-25D67846B219
 Boot ID:			e3d4638d-f003-41e7-a10e-14502d9b39b4
 Kernel Version:		3.10.0-327.el7.x86_64
 OS Image:			Red Hat Enterprise Linux Server 7.2 (Maipo)
 Operating System:		linux
 Architecture:			amd64
 Container Runtime Version:	docker://1.12.2
 Kubelet Version:		v1.4.0
 Kube-Proxy Version:		v1.4.0
ExternalID:			nodea0.example.com
Non-terminated Pods:		(5 in total)
  Namespace			Name						CPU Requests	CPU Limits	Memory Requests	Memory Limits
  ---------			----						------------	----------	---------------	-------------
  default			test-pod-resource				1 (50%)		0 (0%)		0 (0%)		0 (0%)
  kube-system			kube-proxy-amd64-ick75				0 (0%)		0 (0%)		0 (0%)		0 (0%)
  kube-system			kubernetes-dashboard-1171352413-yuqpa		0 (0%)		0 (0%)		0 (0%)		0 (0%)
  kube-system			monitoring-influxdb-3276295126-9690a		0 (0%)		0 (0%)		0 (0%)		0 (0%)
  kube-system			weave-net-fphro					20m (1%)	0 (0%)		0 (0%)		0 (0%)
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.
  CPU Requests	CPU Limits	Memory Requests	Memory Limits
  ------------	----------	---------------	-------------
  1020m (51%)	0 (0%)		0 (0%)		0 (0%)
No events.
```

可以看到以下有用信息

```config
default			test-pod-resource				1 (50%)		0 (0%)		0 (0%)		0 (0%)

Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.
  CPU Requests	CPU Limits	Memory Requests	Memory Limits
  ------------	----------	---------------	-------------
  1020m (51%)	0 (0%)		0 (0%)		0 (0%)
```

可以获得Pod占用的资源和Node当前资源的使用情况。

