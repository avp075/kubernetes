# kubernetes
kustomize, helm, Argocd

kubectl port-forward services/sonarqube-service 9000:9000 & <br />
kubectl port-forward services/db-service 5432:5432 &

kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &

kubectl port-forward service/sonarqube-service 9000:9000 --address=0.0.0.0 &
