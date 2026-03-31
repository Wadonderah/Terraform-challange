# live/eks/kubernetes.tf
# -----------------------------------------------------------------------------
# Kubernetes Workload — nginx Deployment + Service
#
# These resources are deployed into the EKS cluster provisioned in main.tf.
# The depends_on on each resource ensures Terraform will not attempt any
# Kubernetes API call until the EKS node group is fully ready.
# -----------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Namespace — isolate the demo workload from system namespaces
# ---------------------------------------------------------------------------

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.k8s_namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
    }
  }

  depends_on = [module.eks]
}

# ---------------------------------------------------------------------------
# Deployment — two nginx replicas, each exposing port 80
# ---------------------------------------------------------------------------

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx-deployment"
    namespace = kubernetes_namespace.app.metadata[0].name

    labels = {
      app                            = "nginx"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    replicas = var.nginx_replicas

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    # Rolling update strategy — zero downtime deployments

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = "1"
        max_unavailable = "0"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image             = "nginx:${var.nginx_image_tag}"
          name              = "nginx"
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 80
            protocol       = "TCP"
          }

          # Resource requests and limits — critical for the scheduler
          resources {
            requests = {
              cpu    = "100m"   # 0.1 vCPU
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"   # 0.2 vCPU
              memory = "256Mi"
            }
          }

          # Liveness probe — restart the container if nginx stops responding

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }

            initial_delay_seconds = 10
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          # Readiness probe — remove from load balancer until nginx is ready

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }

            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        # Spread replicas across nodes for availability

        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"

          label_selector {
            match_labels = {
              app = "nginx"
            }
          }
        }
      }
    }
  }

  depends_on = [module.eks]
}

# ---------------------------------------------------------------------------
# Service — exposes the Deployment inside the cluster.
# Using ClusterIP here; switch to LoadBalancer to get an AWS NLB.
# ---------------------------------------------------------------------------

resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace.app.metadata[0].name

    labels = {
      app                            = "nginx"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.nginx]
}

# ---------------------------------------------------------------------------
# HorizontalPodAutoscaler — scale between 2 and 5 replicas based on CPU
# ---------------------------------------------------------------------------

resource "kubernetes_horizontal_pod_autoscaler_v2" "nginx" {
  metadata {
    name      = "nginx-hpa"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    min_replicas = var.nginx_replicas
    max_replicas = 5

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.nginx.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.nginx]
}
