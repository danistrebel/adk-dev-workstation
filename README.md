# Cloud Workstation Setup for ADK Developers

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.png)](https://ssh.cloud.google.com/cloudshell/open?cloudshell_git_repo=https://github.com/danistrebel/adk-dev-workstation&cloudshell_tutorial=README.md)

This repo contains a customized [Cloud Workstation](https://cloud.google.com/workstations) image to help AI developers build AI agents with ADK.

## Pre-installed Tools and Libraries

The following tools and libraries are pre-installed on the Cloud Workstation:

### Shell

- [ZSH](https://www.zsh.org/): A powerful shell that operates as both an interactive shell and as a scripting language interpreter.
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions): Fish-like autosuggestions for zsh.
  - [fast-syntax-highlighting](https://github.com/zdharma-zmirror/fast-syntax-highlighting): Optimized syntax highlighting for Zsh.
  - [zsh-completions](https://github.com/zsh-users/zsh-completions): Additional completion definitions for Zsh.
  - [Spaceship Prompt](https://spaceship-prompt.sh/): A Zsh prompt for astronauts.

### Cloud

- [Google Cloud CLI](https://cloud.google.com/sdk/gcloud): The primary CLI tool for Google Cloud.
- [Terraform](https://www.terraform.io/): An infrastructure as code tool that lets you define both cloud and on-prem resources in human-readable configuration files.
- [Helm](https://helm.sh/): The package manager for Kubernetes.

### Python

- [Python 3](https://www.python.org/)
- [uv](https://github.com/astral-sh/uv): An extremely fast Python package installer and resolver, written in Rust.
- [google-adk](https://pypi.org/project/google-adk/): AI Developer Kit for building AI agents.

### Other

- [shellcheck](https://www.shellcheck.net/): A static analysis tool for shell scripts.
- [Node.js](https://nodejs.org/): JavaScript runtime built on Chrome's V8 JavaScript engine.
- [@google/gemini-cli](https://www.npmjs.com/package/@google/gemini-cli): A command-line interface for interacting with the Gemini API.

### VSCode Extensions

- [Python](https://open-vsx.org/extension/ms-python/python)
- [Go](https://open-vsx.org/extension/golang/go)
- [VSCode Icons](https://open-vsx.org/extension/vscode-icons-team/vscode-icons)
- [Gemini CLI VSCode IDE Companion](https://open-vsx.org/extension/google/gemini-cli-vscode-ide-companion)

## Configuration and Service Enablement

```sh
export GCP_PROJECT_ID="your-project-id"
export REGION="europe-west1" 
```

Enable the required services 

```sh
gcloud services enable \
  compute.googleapis.com \
  workstations.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com --project $GCP_PROJECT_ID
```

## Create the docker registry

```sh
gcloud artifacts repositories create dev-tooling \
--repository-format=docker \
--location=$REGION \
--project=$GCP_PROJECT_ID
```

## Build the Cloud Workstation Image 

If the build command below fails, make sure your Compute Engine default service account has the necessary permission or use a custom build service account.

```sh
gcloud builds submit . \
--substitutions "_IMAGE_URL=europe-west1-docker.pkg.dev/$GCP_PROJECT_ID/dev-tooling/workstation" \
--project $GCP_PROJECT_ID
```

## Create a Cloud Workstation Cluster and Configuration

### Workstation Cluster

Create a Cloud Workstation Cluster or re-use an existing Cloud Workstation cluster. Note the following configurations below:

* **`--network`**: Use an existing VPC network or create a dedicated one.
* **`--subnetwork`**: Use an existing VPC subnet or create a dedicated one in the region that you configured in `$REGION`.

Run the following command to create your Cloud Workstation cluster (this can take up to 20 minutes):

```sh
gcloud workstations clusters create dev-cluster \
--region=$REGION \
--network="projects/$GCP_PROJECT_ID/global/networks/default" \
--subnetwork="projects/$GCP_PROJECT_ID/regions/$REGION/subnetworks/default" \
--project=$GCP_PROJECT_ID
```

### Workstation Configuration

Note the following default configuration in the command below and adapt as needed:

* The config below creates a Cloud Workstation cluster with **external IP addresses**.
  * If necessary remove any existing *`compute.vmExternalIpAccess`* organization policy contraints
  * Or specify the *`--disable-public-ip-addresses`* flag and make sure your VPC Subnet has a Cloud Router and Cloud NAT configured.
* **`--container-custom-image`**: points to the custom image you created before.
* **`--cluster`**: points to the cluster you want to re-use or created above.
* **`--machine-type`** and **`--boot-disk-size`**: Describe the compute and storage resources needed by the developer

Run the following command to create your Cloud Workstation configuration and the associated service account (this can take up to 4 minutes):

```sh
gcloud iam service-accounts create workstation \
    --project=$GCP_PROJECT_ID

gcloud artifacts repositories add-iam-policy-binding dev-tooling \
    --project=$GCP_PROJECT_ID \
    --location=$REGION \
    --member="serviceAccount:workstation@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.reader"

gcloud workstations configs create dev-config \
--cluster=dev-cluster \
--region=$REGION \
--machine-type=e2-standard-4 \
--boot-disk-size=100 \
--container-custom-image=europe-west1-docker.pkg.dev/$GCP_PROJECT_ID/dev-tooling/workstation:latest \
--service-account=workstation@$GCP_PROJECT_ID.iam.gserviceaccount.com
--shielded-integrity-monitoring \
--shielded-secure-boot \
--shielded-vtpm \
--project=$GCP_PROJECT_ID
```

## Create your Cloud Workstation Instance

```sh
gcloud workstations create my-workstation \
--cluster=dev-cluster \
--config=dev-config \
--region=$REGION \
--project=$GCP_PROJECT_ID
```

## Operational Considerations

Consider implementing [automated container image rebuilds to synchronize base image updates](https://cloud.google.com/workstations/docs/tutorial-automate-container-image-rebuild) and keeping your workstation secure and up to date.
