# Create a New Service

## Setting up for a new service

Any new service which is part of shoparazzi will be included as a subchart for shoparazzi chart. All the values files are maintained in `values/` folder.


Below are the steps you need to follow to add a new service as a part of shoparazzi charts

1. Create a sub-chart in shoparazzi chart
    ```
      cd charts/shoparazzi/charts
      helm create CHART_NAME
    ```
    
    This will create a basic chart with given name

2. Remove unnecessary k8s resources like ingress if not needed for this service

3. In case of adding ingress, add k8s resource for GKE managed certificates like below

    ```
      apiVersion: networking.gke.io/v1beta1
      kind: ManagedCertificate
      metadata:
        name: {{ $fullName }}
      spec:
        domains:
          - {{ .Values.ingress.domain_name }}
    ```

4. If you need ingress for the service, Add Ingress annotations for managed ssl certs. 

    Remove the default tls settings that come with the ingress template & `ingress.tls` in the values file.

    ```
      {{- if not (hasKey .Values.ingress.annotations "networking.gke.io/managed-certificates") }}
      {{- $_ := set .Values.ingress.annotations "networking.gke.io/managed-certificates" $fullName}}
      {{- end }}
    ```


5. Add a new value `ingress.static_ip_address_name`. Use this add annotate gcp ip-address on ingress. GCP will use this ip-address name to forward the requests to the relevant service

    ```
    {{- if and .Values.ingress.static_ip_address_name (not (hasKey .Values.ingress.annotations "kubernetes.io/ingress.global-static-ip-name")) }}
    {{- $_ := set .Values.ingress.annotations "kubernetes.io/ingress.global-static-ip-name" .Values.ingress.static_ip_address_name}}
    {{- end }}
    ```

5. If you use a GRPC service, change the deployment & service to fit grpc.

6. If you use Http, change the `livenessProbe` & `readinessProbe` http address to match your applications health check endpoints

7. Fill all the details in  `values.yaml` (Image, Tag, etc)

8. To maintain environment variables using secrets & config-maps, change the following

    In deployment.yaml for app `container` 
    ```
    {{- if or .Values.envSecret (.Values.envConfigMap) }}
    envFrom:
      {{- if .Values.envSecret }}
      - secretRef:
          name: {{ .Values.envSecret }}
      {{- end }}

      {{- if .Values.envConfigMap }}
      - configMapRef:
          name: {{ .Values.envConfigMap }}
      {{- end }}
    {{- end }}
    ```

    add `{{ .Values.envConfigMap }}` & `{{ .Values.envSecret }}` in values.yaml


9. Add the chart to dependency in `Chart.yaml`
    ```
    dependencies:
      - name: CHART_NAME
        version: CHART_VERSION
    ```

If you're using [Vault by hashicorp](https://www.vaultproject.io/) to manage secrets

* The base template already creates a ServiceAccount for deploymenmts. This can be bind with valut roles

* Create secrets on valut and bind vault access to the service account used in deploying the pods

* Add vault annotations to inject secrets into the pod using `values.podAnnotations`



## Updating a service

Updating a service is as easy as changing the values file. You can manage autoscaling, images version, etc using this.

Generally the chatrt version for a subchart doesnt need to be changed, If you change it, update in the dependency list for the main chart