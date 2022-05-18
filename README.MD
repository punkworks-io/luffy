# Luffy 

Luffy is the deployment repository which uses helm & deliverybot to provide cd pipelines for easier deployments.

This repo `luffy` was created for a dummy company called Shoparazzi. So, when you fork this for your project, make sure to search for `shoparazzi` & `luffy` globally in the repo and edit accordingly.

This project was tested along with our [infrastructure management repository built on Terraform](https://github.com/punkworks-io/bob)

It also deploys a dummy service called `heimdall` to give an overview of how a new service can be setup using this repo.

It also comes with automation setup on github workflows to test all the changes upon raising a PR


## Tools used

- [helm](https://github.com/helm/helm)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [kubectx + kubens](https://github.com/ahmetb/kubectx)
- [Delivery Bot](https://deliverybot.dev/)
- [jq](https://stedolan.github.io/jq/)
- [chart-testing](https://github.com/helm/chart-testing)
- [yamllint](https://github.com/adrienverge/yamllint)
- [yamale](https://github.com/23andMe/Yamale)



## Design

**Charts and Deployments**

This project contains multiple helm charts in the `charts` folder. 

* `shoparazzi` is the chart that deploys all the required services to K8s.

* `local-data-center` is a chart that simulates the remote databases. More about it in the next section.

Remote deployments are managed by [Delivery Bot](https://deliverybot.dev/). You can find the relevant code for this in `./.github/workflows/cd.yml` and `./.github/deploy.yml`. It even supports Canary deployments in production. Value files for each environment is managed separately in `./values/shoparazzi` folder.


**Local Data Center**

Since Databases in production are generally 3rd party managed services, We want to simulate the data-centers locally and on test. To facilitate this, we created a  chart called local-data-center. It contains all the database instances to be used in local & test environments.

Local Data Center has to be deployed or updated manually on test and local. Delivery Bot doesn't take care of this. If You want to use managed database instances on test, you can safely ignore this on test environment.

To create initial databases on local-data-center, we use `./scripts/setup_local_datacenter.sh`  to store the SQL as a k8s ConfigMap and apply them using a k8s Job. If you add any new databases in the future, you have to edit the above script.


**Kubernetes Namespace & context management**

* We have 2 remote clusters: production & test

* We manage cluster context using kubectx & namespace using kubens

* We have introduced some redundancy in the context & namespace managements for all environments( local, test & production ) so that development code is not accidentally deployed to production.

    * Production environment has production as both namespace & context
    
    * Test environment has test as both namespace & context

    * But, local environment has it's namespace as local & context as minikube. This is because minikube's Nodeports misbehave if the context is changed


**Value files, Config-Maps & Secrets management**

Most services would need you to set environment variables. We manage them using Kubernetes config-maps and secrets. 

* ConfigMap is used for environment variables that are more public e.g, ports, 3rd party end points, etc.

* Secrets is used for environment variables that are more private in nature e.g, DB password, API Keys, etc

* Values are maintained for each environment ( local, test, production and even canary) in `./values/shoparazzi`. We even maintain some hardcoded values for local-data-center. These value files are referenced in `./.github/deploy.yml`


* Secrets & ConfigMaps are injected as environment variables into containers when they start-up. These should be created manually on your clusters and their names are referenced in the values files. 

* `./environments/` folder contains ConfigMaps and Secrets that can be used on local with the local-data-center


To set the secrets & configmaps in your local cluster, Run the following command

`kubectl --context minikube --namespace local apply -f ./environments/shoparazzi`

and change the `values.local.yml` file to reference them like below
```
    envSecret: [service-name]-local-env-secret
    envConfigMap: [service-name]-local-env-config-map
```

Similar procedure can be followed to setup secrets for test & production.


## Initial setup by admin or dev-ops

1. Setup workstation using `./scripts/setup_local_env.sh`

2. Update the project details in `workstation.env`. if you're integrating this with our [infrastructure management repository built on Terraform](https://github.com/punkworks-io/bob), you can use the same details here.

3. Login to gcloud using `gcloud auth login`

4. Setup a new service account for luffy on GCP using `./scripts/setup_gcp_service_account.sh`. This will create a json file at `GCP_luffy_service_account_credentials` mentioned in your workstation.env

5. Login with the above generated service account using
```
    gcloud auth activate-service-account --key-file= /path/to/key.json
```

6. Login to GKE clusters

    Test
    ```
        gcloud container clusters get-credentials test --region asia-south1 --project shoparazzi-test

        kubectx test=gke_shoparazzi-test_asia-south1_test
    ```

    Production
    ```
        gcloud container clusters get-credentials production --region asia-south1 --project shoparazzi-production

        kubectx production=gke_shoparazzi-production_asia-south1_production
    ```

7. Setup Namespaces for test and production

    Test
    ```
        kubectl --context test apply -f ./namespaces/test.yaml
    ```

    Production
    ```
        kubectl --context production apply -f ./namespaces/production.yaml
    ```

8. Setup k8s service accounts for luffy on GKE and give them cluster admin permissions.

    Test 
    ```
        ./scripts/setup_gke_service_account.sh luffy test test
   
        ./scripts/setup_luffy_sa_roles.sh luffy test test
    ```


    Production 
    ```
        ./scripts/setup_gke_service_account.sh luffy production production
   
        ./scripts/setup_luffy_sa_roles.sh luffy production production
    ```

9. Kubeconfigs for the service accounts created in the above step should be set as github secrets to be used while deployment: `TEST_KUBECONFIG` & `PRODUCTION_KUBECONFIG`

Once You're done with this setup, you can delete all service account keys( GCP & GKE ) from your local.

You're currently using the service accounts to interact with the clusters. To interact as your own user, 

* Run `gcloud auth login` and login with your organisation email account

* Repeat steps 6, 7, 8

## Local setup

1. Local Cluster setup

    * Install `minikube`: https://minikube.sigs.k8s.io/docs/start/

    * Start minikube: `minikube start`

2. Setup local env using `./scripts/setup_local_env.sh`

3. Setup your context & namespace:

    * Change kube-context to minikunbe cluster: `kubectx minikube`

    * Create local Namespace: `kubectl --context minikube apply -f ./namespaces/local.yaml`

    * Change default namespace to local: `kubens local`

4. Setup Local Data center using `./scripts/setup_local_datacenter.sh local local`

    If you see any issues with configmap/job already exist. You can delete them using the following command
    ```
        kubectl delete configmap [init-postgresdb.sql]
        kubectl delete jobs [init-postgresdb]
    ```

5. Create a github PAT with `read:packages` role to be able to pull docker images from ghcr.io

6. Register your PAT created above as k8s secret. This can be referenced for ImagePullSecrets in the values file
    ```
    kubectl create secret docker-registry ghcr-read-only-pat --docker-server=ghcr.io --docker-username=<github-username> --docker-password=<github-pat> --docker-email=<github-email>
    ```

7. A local values file named `./values/shoparazzi/values.local.yaml` is created in step 2. Modify the file to fit your requirements

8. Setup environment variables for services in shoparazzi
    `kubectl --context minikube --namespace local apply -f ./environments/shoparazzi`

9. Deploy Shoparazzi helm charts

    ```
    helm install \
        --kube-context minikube \
        --namespace local \
        -f ./values/shoparazzi/values.common.yaml \
        -f ./values/shoparazzi/values.local.yaml \
        shoparazzi \
        ./charts/shoparazzi
    ```

10. To get a url to access nodeport, use: `minikube service [SERVICE_NAME] --url -n local`

11. Pointers to create local values file:
    
    You can copy the sample values file for local environment. 
    
    * Below values are important for local setup
    
    ```
        global:
            shoparazziNamespace: local 
    ```

    * Ingress should be disabled in local. Instead, convert the service to NodePort

    * For all services, Add secrets & config maps like below
    ```
        envSecret: [service-name]-local-env-secret
        envConfigMap: [service-name]-local-env-config-map
    ```

## Adding a new service to helm charts

A detailed documentation on how to add a new service to helm charts is given in `./docs/managing-a-service.md`


## Deployments & Rollback
1. Deployment to test is done when a PR is merged to test branch
2. Deployment to production should be triggered manually from [deliverybot application](https://deliverybot.dev/docs/deploying/). It can also be integrated to work with slack.
3. Rollback is nothing but deploying a previous commit from the deliverybot application
4. Secrets for production & test environments should be applied before deploying the application to mitigate any downtime 
    

## Further improvements

* In `test-on-pr` github workflow, chart testing should be fixed
* deliverybot-helm also supports canary deployments
* deliverybot-helm also supports deploying PRs for review & testing 
* Deliverybot web-app is converted into a self hosted app. Do the relevent migration changes