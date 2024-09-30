# Summary of Assignment 2 Implementation

The goal of this assignment was to deploy a containerized Next.js web application on a local Kubernetes cluster, implement a rolling update strategy for zero-downtime deployments, and scale the application using Kubernetes commands. Below is a step-by-step breakdown of how I approached and solved the task.

## Step-by-Step Implementation

### 1: Familiarize with Kubernetes
I started by familiarizing myself with Kubernetes concepts such as Pods, ReplicaSets, and Deployments. This foundational knowledge was crucial for the subsequent steps.

### 2: Push the Web-App to an Image Registry
I built the Docker image for the Next.js application and pushed it to DockerHub.

```sh
docker build -t markusmayer1/startup-nextjs:latest .
docker login
docker push markusmayer1/startup-nextjs:latest
```

### 3: Set Up the Local Kubernetes Cluster
I installed and then used `kind` to create a local Kubernetes cluster. Below are the commands I used:

```sh
choco install kind
kind create cluster --config=k8s/cluster-config.yaml
kubectl cluster-info --context kind-dev-ops
```

#### [`cluster-config.yaml`](../k8s/cluster-config.yaml)
This file configures the `kind` cluster to map the service port to the host. This allows the service to be accessible from the local machine. The `extraPortMappings` section helps to make the service accessible from the host machine by mapping a port on the host to a port on the container. This setup mimics a real-world LoadBalancer on cloud providers, making it easier to test and develop locally.

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: dev-ops # Name of the cluster
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30000 # Container port which is mapped to the host port
        hostPort: 30000 # Host port where the service will be accessible from the host machine
        protocol: TCP
```

### 4: Deploy the Application
I applied the necessary Kubernetes components and deployment files and used the `kubectl get pods` commands to see the status. The [`components.yaml`](../k8s/components.yaml) included the metrics-server which is needed for the Horizontal Pod Autoscaler (HPA) and to see the CPU utilization in the get commands. 

```sh
kubectl apply -f k8s/components.yaml
kubectl get pods -n kube-system -w
kubectl apply -f k8s/deployment.yaml -f k8s/service.yaml -f k8s/hpa.yaml
kubectl get pods -w
```

#### [`deployment.yaml`](../k8s/deployment.yaml)
Defines the deployment with a rolling update strategy and readiness/liveness probes. The rolling update strategy ensures zero-downtime deployments by updating pods incrementally. The liveness and readiness probes check the health and readiness of the application.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: startup-nextjs-deployment
  labels:
    app: startup-nextjs
spec:
  replicas: 3 # Number of pod replicas to maintain
  selector:
    matchLabels:
      app: startup-nextjs
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1 # Maximum number of pods that can be unavailable during the update
      maxSurge: 3 # Maximum number of extra pods created during the update
  template:
    metadata:
      labels:
        app: startup-nextjs
    spec:
      containers:
        - name: startup-nextjs
          image: markusmayer1/startup-nextjs:latest
          resources:
            requests:
              cpu: "100m" # Minimum CPU requested for this container
            limits:
              cpu: "200m" # Maximum CPU the container is allowed to consume
          ports:
            - containerPort: 3000 # The port exposed by the container
          livenessProbe: # Health check to determine if the container is running correctly otherwise it will be restarted
            httpGet:
              path: /api/health
              port: 3000
            initialDelaySeconds: 30 # Time to wait before starting the first probe after the container starts
            periodSeconds: 10 # How often to perform the check
            timeoutSeconds: 5 # Timeout for each check
          readinessProbe: # Health check to determine if the container is ready to accept traffic
            httpGet:
              path: /api/ready
              port: 3000
            initialDelaySeconds: 30 # Delay before checking the readiness of the container
            periodSeconds: 10 # How often to perform the readiness check
            timeoutSeconds: 5 # Timeout for each check
```

#### [`service.yaml`](../k8s/service.yaml)
Exposes the deployment as a service accessible from the local machine. The `NodePort` type makes the service available on a specific port on the host machine.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: startup-nextjs-service
spec:
  type: NodePort # Exposes the service on a port on each node in the cluster (should be replaced with LoadBalancer for cloud deployments)
  selector:
    app: startup-nextjs # Targets pods with this label
  ports:
    - port: 3000 # Port that the service will expose internally within the cluster
      targetPort: 3000 # The port that the container is listening on
      nodePort: 30000 # External port on the node to access the service from outside the cluster
```

#### [`hpa.yaml`](../k8s/hpa.yaml)
Defines the Horizontal Pod Autoscaler to scale the deployment based on CPU utilization. The HPA automatically adjusts the number of replicas between the set `minReplicas` and `maxReplicas` values to maintain the target CPU utilization.

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: startup-nextjs-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: startup-nextjs-deployment # The deployment to scale
  minReplicas: 3 # Minimum number of replicas
  maxReplicas: 10 # Maximum number of replicas
  targetCPUUtilizationPercentage: 70 # Target CPU usage percentage; pods will scale if utilization is higher than this
```

### 5: Implement Rolling Update Strategy
To ensure zero-downtime deployments, I implemented a rolling update strategy in the [`deployment.yaml`](../k8s/deployment.yaml) file. This strategy updates pods incrementally, ensuring that a portion of the pods remains available and ready to serve traffic during the update process. The `maxUnavailable` and `maxSurge` settings in the deployment configuration control the number of pods that can be unavailable and the number of new pods that can be created during the update, respectively. By using the `get pods` command and monitoring the health and readiness endpoints, I ensured that the application remained responsive throughout the deployment.

```sh
kubectl get pods -w
while true; do echo -n "$(date '+%Y %m %d %H %M %S'): "; curl http://localhost:30000/api/health; echo; sleep 1; done
while true; do echo -n "$(date '+%Y %m %d %H %M %S'): "; curl http://localhost:30000/api/ready; echo; sleep 1; done
```

### 6: Scale the Application
I used the Horizontal Pod Autoscaler (HPA) to scale the application based on CPU utilization. The HPA automatically adjusts the number of replicas to maintain the target CPU utilization, ensuring that the application can handle varying loads efficiently. It is also possible to scale based on memory consumption by configuring the HPA accordingly. 

I generated traffic using Apache HTTP server benchmarking tool and monitored the scaling behavior with the following commands which display resource usage for pods, show detailed information about the HPA, and continuously display the status of pods. The number of pod replicas increased in response to CPU utilization. This check confirmed that the application scaled appropriately.

```sh
ab -n 10000 http://localhost:30000/
kubectl top pods
kubectl describe hpa
kubectl get pods -w
```

### Additional Scaling Strategies
In addition to the Horizontal Pod Autoscaler, I also considered other scaling strategies such as:

- **Cluster Autoscaler**: Automatically adjusts the size of the Kubernetes cluster by adding or removing nodes based on the resource requirements of the pods. This ensures that the cluster can handle varying workloads efficiently.
- **Vertical Pod Autoscaler (VPA)**: Adjusts the resource requests and limits of containers in a pod based on their actual usage. This helps in optimizing resource utilization and ensuring that pods have the necessary resources to perform efficiently.
- **Manual Scaling**: Manually adjusting the number of replicas for a deployment using the `kubectl scale` command. This can be useful for handling predictable traffic patterns or during specific events.


## Conclusion
This assignment required extensive research and troubleshooting as I was new to Kubernetes. I used a [`cluster-config.yaml`](../k8s/cluster-config.yaml) because I could not access the service within the cluster from my host machine. The `kubectl port-forward` command was insufficient as it only forwarded traffic to one pod, not the service. Additionally, I had to download the [`components.yaml`](../k8s/components.yaml) file and add the line `--kubelet-insecure-tls` because the metrics-server did not start without it. Overall, the assignment provided valuable hands-on experience with Kubernetes and container orchestration.