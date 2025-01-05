# kubernetes
kustomize, helm, Argocd

# works well with node port service type

minikube service \<service name\> -p \<profile name\>  -n \<namespace name\>

kubectl port-forward services/sonarqube-service 9000:9000 & <br />
kubectl port-forward services/db-service 5432:5432 &

kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
