# Full Repo tree

```bash
kubapp/
├── .github/
│   ├── workflows/
│   ├── docs/
│
├── docs/
│   ├── execution_flow.md
│   ├── extra_info.md
│   ├── structure
│   ├── gitops.md
│   ├── challenges.md
│   ├── architecture.md
│   ├── security.md
│   ├── observability.md
│   ├── README.md
│
├── scripts/
│   ├── clean_cluster.sh
│   ├── setup_argocd_local.sh
│   ├── commit.sh
│   ├── delete_leftovers.sh
│   ├── sync_route53.sh
│   ├── clean_final.sh
│   ├── functions/
│   │   ├── validate_vars.sh
│   │   ├── logger.sh
│   │   ├── check_data.sh
│   ├── activate.sh
│   ├── postchecks.sh
│   ├── aws_cleanup.sh
│   ├── argocd_login.sh
│   ├── R.md
│   ├── docs/scripts_use.md
│   ├── validate_registry.sh
│   ├── tag_stable_deploy.sh
│   ├── encrypt_secrets.sh
│   ├── cleanup_logs.sh
│   ├── find.sh
│   ├── setup_argocd.sh
│   ├── drift_gitops.sh
│   ├── setup_sops.sh
│   ├── promote.sh
│   ├── drift_state.sh
│   ├── unlock_tf.sh
│   ├── get_state_file.sh
│   ├── run_tf.sh
│   ├── validate_gitops.sh
│   ├── create_secrets.sh
│   ├── apply_argo_secret.py
│   ├── create_values.sh
│   ├── bootstrap_gitops.sh
│   ├── validate.sh
│   ├── register_new_svc.sh
│   ├── remove_app.sh
│   ├── prechecks.sh
│   ├── __pycache__/
│   │   ├── apply_argo_secret.cpython-312.pyc
│   ├── cluster_steps.sh
│   ├── verify_cleanup.sh
│   ├── del_argocd.sh
│   ├── check_cluster.sh
│   ├── README.md
│   ├── get_cert.sh
│
├── gitops/
│   ├── registry/
│   │   ├── dev/
│   │   │   ├── alertmanager.json
│   │   │   ├── argocd.json
│   │   │   ├── weather_app.json
│   │   │   ├── prometheus.json
│   │   │   ├── admin_app.json
│   │   │   ├── url_shortener.json
│   │   │   ├── metrics_app.json
│   │   │   ├── grafana.json
│   ├── charts/
│   │   ├── ingress/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   ├── templates/
│   │   │   │   ├── ingress.yaml
│   │   ├── postgres/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   ├── templates/
│   │   │   │   ├── deployment.yaml
│   │   │   │   ├── pvc.yaml
│   │   │   │   ├── secret.yaml
│   │   │   │   ├── service.yaml
│   │   ├── apps/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   ├── templates/
│   │   │   │   ├── sa.yaml
│   │   │   │   ├── deployment.yaml
│   │   │   │   ├── servicemonitor.yaml
│   │   │   │   ├── hpa.yaml
│   │   │   │   ├── service.yaml
│   ├── secrets/
│   │   ├── github-repo-secret.yaml
│   │   ├── .backup/
│   │   │   ├── grafana-secret.yaml.bak
│   │   │   ├── grafana-secret
│   │   ├── grafana-secret.yaml
│   ├── argocd/
│   │   ├── appset.yaml
│   │   ├── ingress.yaml
│   ├── state/
│   │   ├── current.json
│   ├── ingress/
│   │   ├── prod/
│   │   │   ├── values.yaml
│   │   ├── dev/
│   │   │   ├── argocd.yaml
│   │   │   ├── monitoring.yaml
│   │   │   ├── values.yaml
│   ├── envs/
│   │   ├── stage/
│   │   │   ├── t
│   │   ├── dev/
│   │   │   ├── apps/
│   │   │   │   ├── weather/
│   │   │   │   │   ├── values.yaml
│   │   │   │   ├── urlshortener/
│   │   │   │   │   ├── values.yaml
│   │   │   │   ├── metrics/
│   │   │   │   │   ├── values.yaml
│   │   │   │   ├── admin/
│   │   │   │   │   ├── values.yaml
│   ├── README.md
│
├── docker/
│   ├── weather_app/
│   │   ├── secrets.yml.bak
│   │   ├── backup.yml.bak
│   │   ├── secrets.yml
│   │   ├── app/
│   │   │   ├── reset_alembic.py
│   │   │   ├── local_tz.py
│   │   │   ├── wait_for_db.py
│   │   │   ├── bootstrap_env.sh
│   │   │   ├── sre/
│   │   │   │   ├── system_health.py
│   │   │   │   ├── health.py
│   │   │   │   ├── __init__.py
│   │   │   │   ├── prometheus.py
│   │   │   │   ├── logger.py
│   │   │   │   ├── metrics.py
│   │   │   │   ├── send_alert.py
│   │   │   │   ├── metrics_service.py
│   │   │   │   ├── __pycache__/
│   │   │   │   ├── verify_startup.py
│   │   │   ├── alembic.ini
│   │   │   ├── __init__.py
│   │   │   ├── entrypoint.sh
│   │   │   ├── crud.py
│   │   │   ├── wait_for_db_core.py
│   │   │   ├── schemas.py
│   │   │   ├── db.py
│   │   │   ├── models.py
│   │   │   ├── static/
│   │   │   ├── requirements.txt
│   │   │   ├── test.py
│   │   │   ├── main.py
│   │   │   ├── templates/
│   │   │   ├── alembic/
│   │   │   │   ├── script.py.mako
│   │   │   │   ├── README
│   │   │   │   ├── versions/
│   │   │   │   │   ├── 963eb932bdd4_initial_weather_schema.py
│   │   │   │   ├── env.py
│   │   │   ├── create_sqlite_tables.py
│   │   │   ├── __pycache__/
│   │   ├── kubapp.yml
│   │   ├── Dockerfile
│   │   ├── README.md
│
│   ├── admin_app/
│   │   ├── app.js
│   │   ├── kubapp.yml
│   │   ├── Dockerfile
│   │   ├── package.json
│
│   ├── metrics_app/
│   │   ├── requirements.txt
│   │   ├── app/
│   │   │   ├── logger.py
│   │   │   ├── metrics.py
│   │   │   ├── main.py
│   │   │   ├── worker.py
│   │   │   ├── routes.py
│   │   │   ├── __pycache__/
│   │   ├── kubapp.yml
│   │   ├── Dockerfile
│
│   ├── url_shortener/
│   │   ├── frontend/
│   │   │   ├── index.html
│   │   │   ├── app.js
│   │   │   ├── style.css
│   │   ├── backend/
│   │   │   ├── src/
│   │   │   │   ├── app.js
│   │   │   │   ├── services/urlService.js
│   │   │   │   ├── routes/urlRoutes.js
│   │   │   │   ├── db/memoryStore.js
│   │   │   │   ├── controllers/urlController.js
│   │   ├── kubapp.yml
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── README.md
│
│   ├── docker-compose.yml
│   ├── README.md
│
├── sys_monitor/
│   ├── observability/
│   │   ├── grafana/
│   │   │   ├── dashboards/
│   │   │   │   ├── gitops-overview.json
│   │   │   │   ├── codebase-overview.json
│   │   │   │   ├── github-overview.json
│   │   │   ├── provisioning/
│   │   │   │   ├── dashboards.yml
│   │   │   │   ├── datasources.yml
│   │   ├── prometheus/
│   │   │   ├── alerts.yml
│   │   │   ├── prometheus.yml
│   │   ├── README.md
│
│   ├── exporters/
│   │   ├── gitops/
│   │   │   ├── src/
│   │   │   │   ├── k8s_client.py
│   │   │   │   ├── app.py
│   │   │   │   ├── metrics.py
│   │   │   │   ├── collector.py
│   │   │   │   ├── __pycache__/
│   │   │   ├── requirements.txt
│   │   │   ├── Dockerfile
│   │   ├── github/
│   │   │   ├── src/
│   │   │   │   ├── stream/
│   │   │   │   │   ├── event_types.py
│   │   │   │   │   ├── event_bus.py
│   │   │   │   │   ├── __pycache__/
│   │   │   │   ├── sre_engine/
│   │   │   │   │   ├── slo_policy.py
│   │   │   │   │   ├── slo_engine.py
│   │   │   │   │   ├── slo_state.py
│   │   │   │   │   ├── slo_evaluator.py
│   │   │   │   │   ├── worker.py
│   │   │   │   │   ├── __init__.py
│   │   │   │   │   ├── __pycache__/
│   │   │   │   │   ├── Dockerfile
│   │   │   │   ├── metrics/
│   │   │   │   │   ├── health.py
│   │   │   │   │   ├── registry.py
│   │   │   │   │   ├── __pycache__/
│   │   │   │   ├── routes/
│   │   │   │   │   ├── github.py
│   │   │   │   │   ├── __pycache__/
│   │   │   │   ├── app.py
│   │   │   │   ├── requirements.txt
│   │   │   │   ├── Dockerfile
│
│   ├── docker-compose.yml
│   ├── .env
│
│   ├── cloud/
│   │   ├── test/
│   │   │   ├── locals.tf
│   │   │   ├── providers.tf
│   │   │   ├── terraform.tfstate
│   │   │   ├── vpc.tf
│   │   │   ├── terraform.tfstate.backup
│   │   │   ├── .terraform/providers/registry.terraform.io/hashicorp/aws/5.100.0/linux_amd64/...
│   │   ├── aws/
│   │   │   ├── terraform.tfvars
│   │   │   ├── nginx.ssl.conf
│   │   │   ├── create_env.sh
│   │   │   ├── local.tf
│   │   │   ├── providers.tf
│   │   │   ├── backend.tf
│   │   │   ├── route53.tf
│   │   │   ├── start.sh
│   │   │   ├── nginx.duckdns.conf
│   │   │   ├── boot/
│   │   │   │   ├── terraform.tfvars
│   │   │   │   ├── terraform.tfstate
│   │   │   │   ├── version.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── outputs.tf
│   │   │   │   ├── runner.sh
│   │   │   │   ├── provider.tf
│   │   │   │   ├── s3.tf
│   │   │   │   ├── terraform.tfstate.backup
│   │   │   ├── main.tf
│   │   │   ├── user_data.sh
│   │   │   ├── variables.tf
│   │   │   ├── local_roles.tf
│   │   │   ├── start_letsencrypt.sh
│   │   │   ├── outputs.tf
│   │   │   ├── nginx.http.conf
│
│   ├── docker-compose.yml
│   ├── README.md
│
├── iac/
│   ├── k8s/
│   │   ├── storage_class.tf
│   │   ├── fargate_log.tf
│   │   ├── helm.tf
│   │   ├── namespaces.tf
│   │   ├── readiness.tf
│   │   ├── local.tf
│   │   ├── R.md
│   │   ├── providers.tf
│   │   ├── backend.tf
│   │   ├── find.sh
│   │   ├── sa.tf
│   │   ├── envs/
│   │   │   ├── prod/
│   │   │   │   ├── k8s.tfvars
│   │   │   │   ├── k8s.tfvars.enc
│   │   │   │   ├── backend.hcl
│   │   │   ├── dev/
│   │   │   │   ├── k8s.tfvars
│   │   │   │   ├── k8s.tfvars.enc
│   │   │   │   ├── backend.hcl
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── versions.tf
│   │   │   ├── README.md
│   │
│   ├── infra/
│   │   ├── modules/
│   │   │   ├── acm/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   ├── iam-core/
│   │   │   │   ├── variables.tf
│   │   │   │   ├── outputs.tf
│   │   │   │   ├── roles.tf
│   │   │   ├── logging/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   ├── iam-irsa/
│   │   │   │   ├── ebs.tf
│   │   │   │   ├── iam_policy.json
│   │   │   │   ├── locals.tf
│   │   │   │   ├── efs.tf
│   │   │   │   ├── fluentbit.tf
│   │   │   │   ├── lb.tf
│   │   │   │   ├── apps.tf
│   │   │   │   ├── dns.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── outputs.tf
│   │   │   ├── sg-prep/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   ├── security/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── outputs.tf
│   │   │   ├── eks/
│   │   │   │   ├── sys_nodes.tf
│   │   │   │   ├── default_nodes
│   │   │   │   ├── cluster.tf
│   │   │   │   ├── app_nodes.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── outputs.tf
│   │   │   │   ├── fargate.tf
│   │   │   │   ├── access.tf
│   │   │   ├── efs/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── access_ponits
│   │   │   │   ├── outputs.tf
│   │   │   ├── network/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── outputs.tf
│   │   ├── local.tf
│   │   ├── providers.tf
│   │   ├── backend.tf
│   │   ├── find.sh
│   │   ├── envs/
│   │   │   ├── prod/
│   │   │   │   ├── infra.tfvars.enc
│   │   │   │   ├── backend.hcl
│   │   │   │   ├── infra.tfvars
│   │   │   ├── dev/
│   │   │   │   ├── infra.tfvars.enc
│   │   │   │   ├── backend.hcl
│   │   │   │   ├── infra.tfvars
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── inspect.py
│   │   ├── __pycache__/
│   │   │   ├── inspect.cpython-312.pyc
│   │   ├── versions.tf
│   │   ├── README.md
│
│   ├── manifests/
│   │   ├── local.tf
│   │   ├── providers.tf
│   │   ├── backend.tf
│   │   ├── envs/
│   │   │   ├── dev/
│   │   │   │   ├── manifests.tfvars.enc
│   │   │   │   ├── manifests.tfvars
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── versions.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── alerts/
│   │   │   ├── alert_app.tf
│   │   │   ├── alert_ingress.tf
│   │   │   ├── alert_test.tf
│   │   │   ├── alert_infra.tf
│   │   ├── versions.tf
│   │
│   ├── boot/
│   │   ├── terraform.tfvars
│   │   ├── terraform.tfstate
│   │   ├── version.tf
│   │   ├── variables.tf
│   │   ├── dynamodb.tf
│   │   ├── outputs.tf
│   │   ├── runner.sh
│   │   ├── provider.tf
│   │   ├── s3.tf
│   │   ├── terraform.tfstate.backup
│   │
│   ├── README.md
│
├── .trivyignore
├── .checkov.yaml
├── .sops.yaml
├── .gitignore
└── README.md

