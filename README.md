# Ephemeral GKE project base config (WiP)

Every time you go do a Terraform Tutorial, there are certain things you're expected to have in-place already aside from just a GCP account and an organization like:

- Project
- State Bucket
- Service Accounts
- IAM permissions
- Keys
- VPC, Network, SubNet

Most of the time the author doesn't cover these bits so IMO it's worth having the process for creating them documented somewhere for reference. After you have a base project managed by a service account, you can use the modular version of this project to create/delete projects via terraform without the need for the gCloud CLI.

**The modularized version is [HERE](https://github.com/cloudymax/modules-gcp-tf-base) for people who already have the basics in place**


## Whats NOT in this project (yet)

This does NOT include a bastion jump box, firewall rules, or workload identities. These will be done later in a GKE or Compute VM specific repo. This is just for the basics you need to have terraform manage the life-cycle of GCP projects.

This guide is meant to be a low-effort general solution/example.

If you need a more in-depth guides on GKE, I would recommend reading:

- [GKE private cluster with a bastion host](https://medium.com/google-cloud/gke-private-cluster-with-a-bastion-host-5480b44793a7) by Peter Hrvola
- [How to use a Private Cluster in Kubernetes Engine](https://github.com/GoogleCloudPlatform/gke-private-cluster-demo) by the GCP team
- [Google Cloud Workload Identity with Kubernetes and Terraform](https://www.cobalt.io/blog/google-cloud-workload-identity-with-kubernetes-and-terraform) by Nikola Velkovski

## Setup your base from scratch via gCloud CLI

[Installing the gCloud CLI](https://cloud.google.com/sdk/docs/install)

- Finding your billing account ID:

  ```bash
  gcloud alpha billing accounts list --filter='NAME:<some name>' --format='value(ACCOUNT_ID)'
  ```

- Finding your Organization ID
  
  ```bash
  gcloud organizations list --filter='DISPLAY_NAME:<some org name>' --format='value(ID)'
  ```

- Populate required data

  ```bash
  export PROJECT_NAME="An Easy To Read Name"
  export PROJECT_ID="machine-readable-name"
  export BIG_ROBOT_NAME="myserviceaccount"
  export BIG_ROBOT_EMAIL="none"
  export ORGANIZATION="company.com"
  export ORGANIZATION_ID="none"
  export LOCATION="europe-west1"
  export KEYRING="mykeyring"
  export KEYRING_KEY="terraform-key"
  export BILLING_ACCOUNT="none"
  export GCLOUD_CLI_IMAGE_URL="gcr.io/google.com/cloudsdktool/google-cloud-cli"
  export GCLOUD_CLI_IMAGE_TAG="slim"
  export BACKEND_BUCKET_NAME="$PROJECT_ID-backend-state-storage"
  export BUCKET_PATH_PREFIX:"terraform/state"
  ```

1. Create a new Project and set it as active, then enable billing

    ```bash
    gcloud projects create $PROJECT_ID --name="$PROJECT_NAME"
    gcloud config set project $PROJECT_ID
    gcloud alpha billing projects link $PROJECT_ID --billing-account $BILLING_ACCOUNT
    ```

1. Create a group:

    ```bash
    gcloud identity groups create "admin-bot-group@$ORGANIZATION" --organization=$ORGANIZATION --display-name="top-level bot group" --description="Admin level access   robots"
    ```

2. Give the group some permissions:

    ```bash
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member=group:"admin-bot-group@$ORGANIZATION" \
      --role=roles/iam.serviceAccountUser
      --role=roles/compute.instanceAdmin.v1
      --role=roles/roles/compute.osLogin

    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member=group:"admin-bot-group@$ORGANIZATION" \
      --role=roles/owner
    ```

4. Add the service account to the group for 1 hour:

    ```bash
    gcloud identity groups memberships add \
      --group-email="admin-bot-group@$ORGANIZATION" \
      --member-email="$BIG_ROBOT_EMAIL"
    ```

5. Create a KeyRing and a key

    ```bash
    gcloud kms keyrings create $KEYRING --location=$LOCATION

    gcloud kms keys create $KEYRING_KEY \
        --keyring $KEYRING \
        --location $LOCATION \
        --purpose "encryption"
    ```

6. Then we create a service-account key, auth the key and assume the identity

    ```bash
    gcloud iam service-accounts keys create $(pwd)/$INSECURE_FILE --iam-account="$BIG_ROBOT_EMAIL"

    gcloud auth activate-service-account "$BIG_ROBOT_EMAIL" \
        --key-file=$(pwd)/$INSECURE_FILE  \
        --project=$PROJECT_ID
    ```

7. Encrypt the file. Delete the insecure version after  you're done with it.

    ```bash
    gcloud kms encrypt --key=$KEYRING_KEY \
        --keyring=$KEYRING \
        --location=$LOCATION \
        --ciphertext-file=$(pwd)/secure/$SECURE_FILE \
        --plaintext-file=$(pwd)/$INSECURE_FILE

    rm $INSECURE_FILE
    ```

8. Create backend bucket for the state and enable versioning:

    ```bash
    gsutil mb gs://$BACKEND_BUCKET_NAME

    gsutil versioning set on gs://$BACKEND_BUCKET_NAME
    ```

7. Init terraform

    ```bash
    terraform init -backend-config "bucket=gke-howdy-backend-state-storage" \
      -backend-config "prefix=$BUCKET_PATH_PREFIX" \
      -backend-config "credentials=../$INSECURE_FILE" 
    ```

## Managing with Terraform through a service account

After you have the base resources in place and your have a service-account identity + credentials, you can run terraform locally or in a CI system like GitHub Actions or Jenkins.

- Enable Services 

  ```bash
  gcloud services enable compute.googleapis.com
  # todo: gather all services
  ```

## Terraform Installation Methods

I like using tfenv to manage my terrform install and versioning. Link: https://github.com/tfutils/tfenv

1. Install Via tfenv (brew only)

    ```bash
    # install via brew
    brew install tfenv

    # install the latest terraform version
    tfenv install latest

    # select the version to use 
    tfenv use 1.1.9

    # add to path if prompted
    export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"

    # verify by checking version
    terraform -version
    ```

2. Install Via Docker

    Add the --entrypoint /bin/sh flag to get a shell.

    ```bash
    docker pull hashicorp/terraform:latest

    cd /GKE-HelloWorld

    docker run -it -v "$(pwd)/secure:/root/secure" -v "$(pwd)/terraform:/root/terraform" --workdir "/root/terraform" hashicorp/terraform:latest init
    ```
