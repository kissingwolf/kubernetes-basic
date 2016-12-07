# Kubernetes 1.4 高级课程

###### kissingwolf@gmail.com

[TOC]

## Kubernetes 集群管理

### Node 节点管理

在前面基础课程中，我们介绍了Kubernetes 集群是由两种基础设备组成的：Master和Node。Master负责管理和维护Kubernetes集群信息，并向Node下放任务和接收反馈信息。Node负责集群负载，在Node上真实的运行Kubernetes Pod 以及容器实例。

随着Kubernetes集群的构建，Node节点数量会不断增加，Node节点由于其自身的故障或网络原因也会出现离线或剔除。我们就需要对其做相应的操作。

#### Node节点的隔离和恢复

在硬件或网络维护的时候，我们需要将某些Node 节点进行隔离，使其脱离Kubernetes 集群的调度。Node 节点脱离Kubernetes集群调度的目的是为了避免Master 再为其分配Pod 运行，原有运行在其上的Pod 并不会自动迁移到其它没有脱离Kubernetes 集群的Node节点上。如果希望Node 节点离线，并快速将脱离Kubernetes 调度的Node 节点上Pod 转移，需要手工完成操作。

隔离和恢复Node 节点有两种方法，使用配置文件或手工执行命令。

首先我们查看当前的Kubernetes 集群节点状态：

```shell
[root@master0 ~]# kubectl  get node
NAME                  STATUS    AGE
master0.example.com   Ready     15d
nodea0.example.com    Ready     15d
nodeb0.example.com    Ready     15d
```

你看到结果应该和上面类似，masterN 是Kubernetes 集群的Master ，nodeaN 和 nodebN 是Kubernetes 集群中的Node 节点。整个环境是在基础课程中就安装完成的标准环境，如果你的环境有问题，请在你的物理机上修改并运行init_k8s.sh，初始化Kubernetes试验环境。

使用配置文件方法，首先需要创建配置文件unsheduleable_node.yaml，内容如下：

```yaml
apiVersion: v1  # 配置版本
kind: Node # 配置类型
metadata: # 元数据
  name: nodeb0.example.com # 配置文件元数据名
  labels: # 标签名
    kubernetes.io/hostname: nodeb0.example.com # 需要隔离的 Node 节点
spec:
  unschedulable: true # spec.unschedulable 设置为true 时，Node 节点被隔离，
                      # 设置为false时，Node 节点恢复。 默认值为false
```

在默认情况下，nodebN.example.com 节点的状态和信息如下：

```shell
[root@master0 ~]# kubectl describe node nodeb0.example.com
Name:			nodeb0.example.com
Labels:			beta.kubernetes.io/arch=amd64
			beta.kubernetes.io/os=linux
			kubernetes.io/hostname=nodeb0.example.com 
Taints:			<none>
CreationTimestamp:	Tue, 22 Nov 2016 12:49:20 +0800
Phase:
Conditions:
  Type			Status	LastHeartbeatTime			LastTransitionTime			Reason				Message
  ----			------	-----------------			------------------			------				-------
  OutOfDisk 		False 	Wed, 07 Dec 2016 14:05:44 +0800 	Wed, 23 Nov 2016 16:36:20 +0800 	KubeletHasSufficientDisk 	kubelet has sufficient disk space available
  MemoryPressure 	False 	Wed, 07 Dec 2016 14:05:44 +0800 	Tue, 22 Nov 2016 12:49:19 +0800 	KubeletHasSufficientMemory 	kubelet has sufficient memory available
  DiskPressure 		False 	Wed, 07 Dec 2016 14:05:44 +0800 	Tue, 22 Nov 2016 12:49:19 +0800 	KubeletHasNoDiskPressure 	kubelet has no disk pressure
  Ready 		True 	Wed, 07 Dec 2016 14:05:44 +0800 	Wed, 23 Nov 2016 16:36:20 +0800 	KubeletReady 			kubelet is posting ready status
Addresses:		172.25.0.12,172.25.0.12
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
 System UUID:			C7207044-587A-4F66-9AF7-7E7262AD9DA9
 Boot ID:			3ddb17ed-0d77-4e17-91d9-b36301640f11
 Kernel Version:		3.10.0-327.el7.x86_64
 OS Image:			Red Hat Enterprise Linux Server 7.2 (Maipo)
 Operating System:		linux
 Architecture:			amd64
 Container Runtime Version:	docker://1.12.2
 Kubelet Version:		v1.4.0
 Kube-Proxy Version:		v1.4.0
ExternalID:			nodeb0.example.com
Non-terminated Pods:		(4 in total)
  Namespace			Name						CPU Requests	CPU Limits	Memory Requests	Memory Limits
  ---------			----						------------	----------	---------------	-------------
  kube-system			kube-proxy-amd64-gzmv5				0 (0%)		0 (0%)		0 (0%)		0 (0%)
  kube-system			monitoring-grafana-927606581-45lpl		0 (0%)		0 (0%)		0 (0%)		0 (0%)
  kube-system			monitoring-influxdb-3276295126-ec2nf		0 (0%)		0 (0%)		0 (0%)		0 (0%)
  kube-system			weave-net-cfenz					20m (1%)	0 (0%)		0 (0%)		0 (0%)
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.
  CPU Requests	CPU Limits	Memory Requests	Memory Limits
  ------------	----------	---------------	-------------
  20m (1%)	0 (0%)		0 (0%)		0 (0%)
```

请保证你的配置信息与实际nodebN.example.com 节点的信息信息中Name和Lables显示相关项目一致。

通过kubectl replace 命令修改Node 状态：

```shell
[root@master0 ~]# kubectl replace -f unsheduleable_node.yaml
node "nodeb0.example.com" replaced
```

随后查看Node 状态，可以看到Node 节点 nodebN.example.com 的状态由之前的Ready 转化为Ready，SchedulingDisabled。

```shell
[root@master0 ~]# kubectl get node
NAME                  STATUS                     AGE
master0.example.com   Ready                      15d
nodea0.example.com    Ready                      15d
nodeb0.example.com    Ready,SchedulingDisabled   15d
```

之后再建立Pod，Kubernetes 集群将不再分配给Node 节点 nodebN.example.com 。

使用命令行直接操作也是可以的，命令为kubectl patch:

```shell
[root@master0 ~]# kubectl get node
NAME                  STATUS                     AGE
master0.example.com   Ready                      15d
nodea0.example.com    Ready                      15d
nodeb0.example.com    Ready,SchedulingDisabled   15d

[root@master0 ~]# kubectl patch node nodea0.example.com -p '{"spec": {"unschedulable": true}}'
"nodea0.example.com" patched

[root@master0 ~]# kubectl get node
NAME                  STATUS                     AGE
master0.example.com   Ready                      15d
nodea0.example.com    Ready,SchedulingDisabled   15d
nodeb0.example.com    Ready,SchedulingDisabled   15d

[root@master0 ~]# kubectl patch node nodea0.example.com -p '{"spec": {"unschedulable": false}}'
"nodea0.example.com" patched

[root@master0 ~]# kubectl patch node nodeb0.example.com -p '{"spec": {"unschedulable": false}}'
"nodeb0.example.com" patched

[root@master0 ~]# kubectl get node
NAME                  STATUS    AGE
master0.example.com   Ready     15d
nodea0.example.com    Ready     15d
nodeb0.example.com    Ready     15d
```

Kubernetes 1.4 中使用更加简洁的方式配置Node 节点的隔离和恢复，kubectl 新的子命令cordon和uncordon 同样可以完成隔离和恢复任务：

```shell
[root@master0 ~]# kubectl cordon nodeb0.example.com
node "nodeb0.example.com" cordoned
[root@master0 ~]# kubectl get node
NAME                  STATUS                     AGE
master0.example.com   Ready                      15d
nodea0.example.com    Ready                      15d
nodeb0.example.com    Ready,SchedulingDisabled   15d
[root@master0 ~]# kubectl uncordon nodeb0.example.com
node "nodeb0.example.com" uncordoned
[root@master0 ~]# kubectl get node
NAME                  STATUS    AGE
master0.example.com   Ready     15d
nodea0.example.com    Ready     15d
nodeb0.example.com    Ready     15d
```

#### Node节点的添加和剔除

首先，我们必须知道在Kubernetes 集群中，我们碰到最多且最棘手的问题是服务器容量不足，这时我们需要购买新的服务器，添加新的Node 节点，以达到系统水平扩展的目的。

在Kubernetes 1.4 集群中，添加新的节点非常简单，只需要在新Node 节点上安装 Kubernetes 1.4 软件，配置其基础运行环境后执行kubeadm jion 命令就可以将其添加到已经存在的Kubernetes 1.4 集群中。

接下来我们在现有的Kubernetes 1.4 集群中添加一台新的Node 节点 nodecN.example.com 。 在我们的实验环境中基础设备已经为大家预先配置。

启动nodec 虚拟机：

```shell
[kiosk@foundation0 Desktop]$ rht-vmctl reset nodec
Are you sure you want to reset nodec? (y/n) y
Powering off nodec.
Resetting nodec.
Creating virtual machine disk overlay for up500-nodec-vda.qcow2
Starting nodec.
```

连接nodec 虚拟机，请注意你的设备foundation号：

```shell
[kiosk@foundation0 Desktop]$ ssh root@nodec0
Last login: Sat Jun  4 14:39:46 2016 from 172.25.0.250
[root@nodec0 ~]#
```

按照基础课程中讲到的方法初始化Node 节点 nodecX.example.com 的环境

```shell
[root@nodec0 ~]# systemctl stop firewalld

[root@nodec0 ~]# systemctl  disable NetworkManager

[root@nodec0 ~]# systemctl  stop NetworkManager.service

[root@nodec0 ~]# setenforce 0

[root@nodec0 ~]# sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

[root@nodec0 ~]# yum install wget bzip2 net-tools -y

[root@nodec0 ~]# wget http://classroom.example.com/materials/kubernetes-1.4.repo -O /etc/yum.repos.d/k8s.rep

[root@nodec0 ~]# yum install docker-engine kubeadm kubectl kubelet kubernetes-cni -y

[root@nodec0 ~]# systemctl  enable docker  kubelet

[root@nodec0 ~]# systemctl  enable docker

[root@nodec0 ~]# wget http://classroom.example.com/materials/k8s-imgs/k8s-1.4-node-img.tbz

[root@nodec0 ~]# for i in ./k8s-1.4-node-img/*.img ; do docker load -i $i ; done

[root@nodec0 ~]# wget http://classroom.example.com/materials/k8s-imgs/heapster-img.tbz

[root@nodec0 ~]# tar -jxf heapster-img.tbz

[root@nodec0 ~]# for i in ./heapster/*.img ; do docker load -i $i ; done
```

将Node 节点 nodecX.example.com 添加入现有的Kubernetes 1.4 集群，请将token值替换为你自己的：

```shell
[root@nodec0 ~]# kubeadm join --token=0a349c.013fd0942f0c8498 172.25.0.10
<util/tokens> validating provided token
<node/discovery> created cluster info discovery client, requesting info from "http://172.25.0.10:9898/cluster-info/v1/?token-id=0a349c"
<node/discovery> cluster info object received, verifying signature using given token
<node/discovery> cluster info signature and contents are valid, will use API endpoints [https://172.25.0.10:443]
<node/csr> created API client to obtain unique certificate for this node, generating keys and certificate signing request
<node/csr> received signed certificate from the API server, generating kubelet configuration
<util/kubeconfig> created "/etc/kubernetes/kubelet.conf"

Node join complete:
* Certificate signing request sent to master and response
  received.
* Kubelet informed of new secure connection details.

Run 'kubectl get nodes' on the master to see this machine join.
```

在Master 节点上执行kubectl get node 可以看到新的节点已经加入：

```shell
[root@master0 ~]# kubectl get nodes
NAME                  STATUS    AGE
master0.example.com   Ready     15d
nodea0.example.com    Ready     15d
nodeb0.example.com    Ready     2h
nodec0.example.com    Ready     10s
```

需要注意的是token值，如果你忘记在之前基础课程创建Kubernetes 1.4 集群时备份token值了，也没有关系，在Master 节点执行如下指令，可以得到当前Kubernetes 1.4 集群的token值。

```shell
[root@master0 ~]# kubectl -n kube-system get secret clusterinfo -o yaml | grep token-map | awk '{print $2}' | base64 -d | sed "s|{||g;s|}||g;s|:|.|g;s/\"//g;" | xargs echo
0a349c.013fd0942f0c8498
```

