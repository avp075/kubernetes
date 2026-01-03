## 1. Add label


add lables to subnets 
```
 kubernetes.io/cluster/kubernetes owned
 kubernetes.io/role/elb				1
```

```
ubuntu@ip-172-31-21-188:~$ kubectl get node
NAME               STATUS   ROLES           AGE     VERSION
ip-172-31-17-138   Ready    <none>          15s     v1.31.14
ip-172-31-17-33    Ready    <none>          12s     v1.31.14
ip-172-31-23-26    Ready    <none>          19s     v1.31.14
ubuntu@ip-172-31-21-188:~$
ubuntu@ip-172-31-21-188:~$
```

## 2. Add provider ID

```
kubectl patch node ip-172-31-17-138  -p '{"spec":{"providerID":"aws:///us-east-2/i-0bb460311290f0a25"}}'
kubectl patch node ip-172-31-17-33 -p '{"spec":{"providerID":"aws:///us-east-2/i-0bb83ddf89200ba3f"}}'
kubectl patch node ip-172-31-23-26  -p '{"spec":{"providerID":"aws:///us-east-2/i-06cd1d9d31d7ce246"}}'
```

## 3. Install Helm and the AWS Load Balancer Controller:

```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

#Install aws-load-balancer controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=kubernetes #update cluster name if needed

```

Check pods status:

```
kubectl get pods -n kube-system -l=app.kubernetes.io/instance=aws-load-balancer-controller
kubectl logs -n kube-system -l=app.kubernetes.io/instance=aws-load-balancer-controller
```

## 4. Updated ALB Controller 


```
kubectl -n kube-system edit deployment aws-load-balancer-controller
```

Right under spec.template.spec:, add these two lines:

```
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet

```

```
kubectl rollout restart deployment aws-load-balancer-controller -n kube-system
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -o wide
```



## 5. Use same ALB for multiple ingress

Update in ingress.yaml as below

```
metadata:
  annotations:
    alb.ingress.kubernetes.io/group.name: my-shared-alb
```

