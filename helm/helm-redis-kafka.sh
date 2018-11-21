appVersion: 4.0.8
description: Open source, advanced key-value store. It is often referred to as a data
  structure server since keys can contain strings, hashes, lists, sets and sorted
  sets.
engine: gotpl
home: http://redis.io/
icon: https://bitnami.com/assets/stacks/redis/img/redis-stack-220x234.png
keywords:
- redis
- keyvalue
- database
maintainers:
- email: containers@bitnami.com
  name: bitnami-bot
name: redis
sources:
- https://github.com/bitnami/bitnami-docker-redis
version: 1.1.15

---
## Bitnami Redis image version
## ref: https://hub.docker.com/r/bitnami/redis/tags/
##
image: bitnami/redis:4.0.8-r2

## Specify a imagePullPolicy
## ref: http://kubernetes.io/docs/user-guide/images/#pre-pulling-images
##
imagePullPolicy: IfNotPresent

## Kubernetes service type
serviceType: NodePort

## Pod Security Context
securityContext:
  enabled: true
  fsGroup: 1001
  runAsUser: 1001

## Use password authentication
usePassword: true

## Redis password
## Defaults to a random 10-character alphanumeric string if not set and usePassword is true
## ref: https://github.com/bitnami/bitnami-docker-redis#setting-the-server-password-on-first-run
##
# redisPassword:

## Redis command arguments
##
## Can be used to specify command line arguments, for example:
##
## args:
##  - "redis-server"
##  - "--maxmemory-policy volatile-ttl"
args:

## Redis additional command line flags
##
## Can be used to specify command line flags, for example:
##
## redisExtraFlags:
##  - "--maxmemory-policy volatile-ttl"
##  - "--repl-backlog-size 1024mb"
redisExtraFlags:

## Enable persistence using Persistent Volume Claims
## ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
##
persistence:
  enabled: true

  ## The path the volume will be mounted at, useful when using different
  ## Redis images.
  path: /bitnami

  ## The subdirectory of the volume to mount to, useful in dev environments and one PV for multiple services.
  subPath: ""

  ## A manually managed Persistent Volume and Claim
  ## Requires persistence.enabled: true
  ## If defined, PVC must be created manually before volume will be bound
  # existingClaim:

  ## redis data Persistent Volume Storage Class
  ## If defined, storageClassName: <storageClass>
  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  ## If undefined (the default) or set to null, no storageClassName spec is
  ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
  ##   GKE, AWS & OpenStack)
  ##
  # storageClass: "-"
  accessMode: ReadWriteOnce
  size: 8Gi

metrics:
  enabled: false
  image: oliver006/redis_exporter
  imageTag: v0.11
  imagePullPolicy: IfNotPresent
  resources: {}
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9121"

## Configure resource requests and limits
## ref: http://kubernetes.io/docs/user-guide/compute-resources/
##
resources:
  requests:
    memory: 256Mi
    cpu: 100m

## Node labels and tolerations for pod assignment
## ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector
## ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#taints-and-tolerations-beta-feature
nodeSelector: {}
tolerations: []

## Additional pod labels
## ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
podLabels: {}

## annotations for redis pods
podAnnotations: {}

networkPolicy:
  ## Enable creation of NetworkPolicy resources.
  ##
  enabled: false

  ## The Policy model to apply. When set to false, only pods with the correct
  ## client label will have network access to the port Redis is listening
  ## on. When true, Redis will accept connections from any source
  ## (with the correct destination port).
  ##
  allowExternal: true

service:
  annotations: {}
  loadBalancerIP:



# helm install --name=redis1 stable/redis  -f frb-redis-1.yaml
# helm install --name=redis2 stable/redis  -f frb-redis-2.yaml

kubectl get secret --namespace default redis1-redis -o jsonpath="{.data.redis-password}" | base64 --decode

redis1 
D6YUmRP2oT

redis2
dwhzYZ2zhs


helm install --name=kafka1 incubator/kafka -f frb-kafka-1.yaml
helm install --name=kafka2 incubator/kafka -f frb-kafka-2.yaml
helm install --name=testkafka incubator/kafka -f test-kafka.yaml


apiVersion: v1
kind: Pod
metadata:
  name: testclient
  namespace: kafka
spec:
  containers:
  - name: kafka
    image: solsson/kafka:0.11.0.0
    command:
      - sh
      - -c
      - "exec tail -f /dev/null"
      
-- note



/usr/bin/kafka-topics --zookeeper testkafka-zookeeper:2181 --topic RAW-DN --create --partitions 1 --replication-factor 1
/usr/bin/kafka-topics --zookeeper testkafka-zookeeper:2181 --topic RAW-EV --create --partitions 1 --replication-factor 1
/usr/bin/kafka-topics --zookeeper testkafka-zookeeper:2181 --topic RAW-UC --create --partitions 1 --replication-factor 1
/usr/bin/kafka-topics --zookeeper testkafka-zookeeper:2181 --topic RAW-UI --create --partitions 1 --replication-factor 1


Once you have the testclient pod above running, you can list all kafka
topics with:

  kubectl -n default exec testclient -- /usr/bin/kafka-topics --zookeeper testkafka-zookeeper:2181 --list

To create a new topic:

  kubectl -n default exec testclient -- /usr/bin/kafka-topics --zookeeper testkafka-zookeeper:2181 --topic test1 --create --partitions 1 --replication-factor 1

To listen for messages on a topic:

  kubectl -n default exec -ti testclient -- /usr/bin/kafka-console-consumer --bootstrap-server testkafka-kafka:9092 --topic test1 --from-beginning

To stop the listener session above press: Ctrl+C

To start an interactive message producer session:
  kubectl -n default exec -ti testclient -- /usr/bin/kafka-console-producer --broker-list testkafka-kafka-headless:9092 --topic test1

To create a message in the above session, simply type the message and press "enter"
To end the producer session try: Ctrl+C



kubectl -n default exec kafka1 -- /usr/bin/kafka-topics --zookeeper testkafka-zookeeper:2181 --list