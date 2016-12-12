#!/bin/bash 
Kubeadmin_Init_Token="0a349c.013fd0942f0c8498"
Foundation_Num="0"
rht-vmctl reset master
rht-vmctl reset nodea
rht-vmctl reset nodeb
rht-vmctl reset nodec
sleep 10
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "systemctl disable firewalld " ; done
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "systemctl stop firewalld " ; done
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "systemctl disable  NetworkManager " ; done
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "systemctl stop  NetworkManager " ; done
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "setenforce 0 " ; done
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config " ; done
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "grep "SELINUX=" /etc/selinux/config " ; done
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "yum install wget bzip2 net-tools -y " ; done
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "wget http://classroom.example.com/materials/kubernetes-1.4.repo -O /etc/yum.repos.d/k8s.repo " ; done
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "yum install docker-engine kubeadm kubectl kubelet kubernetes-cni -y " ; done
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "systemctl enable docker kubelet " ; done
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "systemctl start docker " ; done
ssh root@master$Foundation_Num "wget http://classroom.example.com/materials/k8s-imgs/k8s-1.4-master-img.tbz "
for i in nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "wget http://classroom.example.com/materials/k8s-imgs/k8s-1.4-node-img.tbz " ; done
ssh root@master$Foundation_Num "tar -jxf k8s-1.4-master-img.tbz" 
ssh root@master$Foundation_Num 'for i in ./k8s-1.4-master-img/*.img ; do docker load -i  $i ; done'
for i in nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "tar -jxf k8s-1.4-node-img.tbz " ; done
for i in nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i 'for i in ./k8s-1.4-node-img/*.img ; do docker load -i $i  ; done' ; done
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "getenforce " ; done
for i in master$Foundation_Num nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i "systemctl start kubelet " ; done
ssh root@master$Foundation_Num "kubeadm init --token $Kubeadmin_Init_Token"
ssh root@master$Foundation_Num "kubectl get pod --all-namespaces"
for i in nodea$Foundation_Num nodeb$Foundation_Num nodec$Foundation_Num ; do ssh root@$i " kubeadm join --token $Kubeadmin_Init_Token 172.25.0.10 "  ; done
ssh root@master$Foundation_Num "kubectl get nodes"
ssh root@master$Foundation_Num "kubectl get pod --all-namespaces"
ssh root@master$Foundation_Num "kubectl apply -f http://classroom.example.com/materials/k8s-conf/weave-kube"
ssh root@master$Foundation_Num "kubectl get pod --all-namespaces"
ssh root@master$Foundation_Num "kubectl apply -f http://classroom.example.com/materials/k8s-conf/kubernetes-dashboard.yaml"
ssh root@master$Foundation_Num "kubectl get pod --all-namespaces"
