
argocd login argocd.rundailytest.online \
  --username admin \
  --password "$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)" \
  --grpc-web

ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d)

argocd login argocd.rundailytest.online \
  --username admin \
  --password "$ADMIN_PASSWORD" \
  --grpc-web

argocd account update-password \
  --account kubapp \
  --current-password "$ADMIN_PASSWORD" \
  --new-password 'MyStrongDevopsPassword!'

argocd account generate-token --account kubapp
