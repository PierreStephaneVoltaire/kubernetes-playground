# Kubernetes Playground

## Overview

The **Kubernetes Playground** is a sandbox env designed to experiment with new technologies and deploy applications using Kubernetes. The primary focus is on automation, GitOps, Experimentation and cloud-native tools like Terraform, EKS, ArgoCD, Crossplane, Jenkins, and HashiCorp Vault. The project is divided into multiple repositories, each serving a specific purpose.

## Repository Structure

### **Core Infrastructure**

- [kubernetes-playground](https://github.com/PierreStephaneVoltaire/kubernetes-playground) - Main repository that deploys an **EKS cluster** with **spot node groups** using Terraform.
- [kubernetes-playground-network](https://github.com/PierreStephaneVoltaire/kubernetes-playground-network) - Basic networking setup, including **VPC and subnets** using Terraform.
- [kubernetes-playground-domain](https://github.com/PierreStephaneVoltaire/kubernetes-playground-domain) - Terraform repository for managing **A records in Route 53** and wildcard **ACM certs**.

### **GitOps & Application Deployment**

- [kubernetes-playground-crossplane](https://github.com/PierreStephaneVoltaire/kubernetes-playground-crossplane) - Crossplane setup with Terraform and ArgoCD.
- [kubernetes-playground-crossplane-providers](https://github.com/PierreStephaneVoltaire/kubernetes-playground-crossplane-providers) - Configures AWS providers for Crossplane to **manage AWS resources as Kubernetes objects**.
- [kubernetes-playground-jenkins](https://github.com/PierreStephaneVoltaire/kubernetes-playground-jenkins) - Jenkins setup using ArgoCD, with **Cognito OIDC for authentication**.
- [kubernetes-playground-auth](https://github.com/PierreStephaneVoltaire/kubernetes-playground-auth) - Cognito setup for **future OIDC integrations** with ArgoCD, Vault, and Jenkins.
- [kubernetes-playground-vault](https://github.com/PierreStephaneVoltaire/kubernetes-playground-vault) - HashiCorp Vault setup using Terraform and ArgoCD to **manage secrets, credentials, and configurations**.

## TODO / Future Enhancements

- **Service Mesh**: Integrate **Istio** into the EKS cluster.
- **Access Management**: Implement a **post-authentication Lambda function** for Cognito to provide **default read-only access** to applications.
- **Multi-Cloud Kubernetes**: Deploy **AKS (Azure Kubernetes Service)** and manage both **EKS and AKS with ArgoCD**.
- **Self-Service Portal**: Use Jenkins and ArgoCD to build a **self-service portal** that automates the creation of repositories, AWS resources, and other cloud services to accelerate future project setup.

### Author: [Pierre Stephane Voltaire](https://github.com/PierreStephaneVoltaire)



