resource "kind_cluster" "default" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }

    node {
      role = "worker"
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  namespace        = "argocd"
  create_namespace = true

  depends_on = [
    kind_cluster.default
  ]
}

## Ref: https://bit.ly/3L1oCq2
data "external" "env" {
  program = ["${path.module}/env.sh"]
}

resource "kubernetes_secret" "create_git_private_repo_secret" {
  type = "Opaque"
  metadata {
    name      = "argocd-git-secret"
    namespace = helm_release.argocd.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    "url"      = "https://github.com/nicolastakashi/k8s-labs.git"
    "username" = "not-used"
    "password" = data.external.env.result["gh_token"]
  }

  depends_on = [
    kind_cluster.default
  ]
}

## admin@123
resource "null_resource" "update_argocd_password" {
  triggers = {
    key = uuid()
  }

  provisioner "local-exec" {
    command = <<EOF
      printf "\Updating argocd password...\n"
      kubectl -n ${helm_release.argocd.namespace} patch secret argocd-secret \
        -p '{"stringData": {
          "admin.password": "$2a$12$WkH.eHw1XdRD7G6WDgwuBeAzneW4VQqjFsEmgH0BcS.hKLaJ1gSF6",
          "admin.passwordMtime": "'$(date +%FT%T%Z)'"
        }}'
    EOF
  }

  depends_on = [
    kubernetes_secret.create_git_private_repo_secret
  ]
}

resource "null_resource" "create_root_argoapp" {
  triggers = {
    key = uuid()
  }

  provisioner "local-exec" {
    command = <<EOF
      printf "\nCreating root argoapp...\n"
      kubectl --namespace ${helm_release.argocd.namespace} \
        apply -f ./files/argocd-root-app.yaml
    EOF
  }
}
