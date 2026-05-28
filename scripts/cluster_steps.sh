
## Short destroy philosophy
delete applications first
delete namespaces second
delete cloud leftovers third
terraform destroy last


# Steps
kubectl get ns
kubectl get all -A
kubectl get ingress -A
kubectl get pvc -A
kubectl get crd


# To inspect everything namespaced
kubectl api-resources --verbs=list --namespaced -o name \
| xargs -n 1 kubectl get -A --ignore-not-found


# Delete GitOps controllers
kubectl get applications.argoproj.io -A
kubectl delete applications.argoproj.io --all -A

# If deletion hangs
kubectl get applications.argoproj.io -A -o name \
| xargs -r -I{} kubectl patch {} \
-p '{"metadata":{"finalizers":[]}}' --type=merge

kubectl delete deployment --all -n ingress
kubectl delete service --all -n ingress
kubectl delete ingress --all -n ingress
kubectl delete pvc --all -n ingress

kubectl delete deployment --all -n admin
kubectl delete deployment --all -n user

kubectl delete all --all -n ingress

#Verify namespaces are empty
kubectl api-resources --verbs=list --namespaced -o name \
| xargs -n 1 kubectl get -n ingress --ignore-not-found


kubectl delete ns ingress
kubectl delete ns argocd
kubectl delete ns admin
kubectl delete ns user

# If namespace gets stuck in Terminating
kubectl get ns ingress -o json | jq '.spec.finalizers'

kubectl replace --raw "/api/v1/namespaces/ingress/finalize" \
-f <(kubectl get ns ingress -o json | jq '.spec.finalizers=[]')



kubectl get crd | grep argoproj
kubectl delete crd applications.argoproj.io
kubectl delete crd applicationsets.argoproj.io
kubectl delete crd appprojects.argoproj.io


kubectl get all -A
kubectl get ns
kubectl get crd

