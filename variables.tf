variable "subscription_id" {
  description = "Azure Subscription ID"
}

variable "app_id" {
  description = "Azure Kubernetes Service Cluster service principal"
}

variable "password" {
  description = "Azure Kubernetes Service Cluster password"
}

variable "kubernetes_version" {
    description = "Kubernetes version"
    default = "1.29.7"
}