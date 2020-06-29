# Frequenty Asked Questions

### What are pods, clusters, deployment configs, routes etc.?

This answer will try to provide simple and concise answers for you, a neo research intern or PhD student who has no idea what to do in day 1 and does not like to waste time à la RTFM. *Real men copycat from someone else :) *

A **pod** is a running container of a Docker image with the sole aim to run a single command. Be careful, you *don't create pods directly*. You create *deployment configs* which create your pod (among with other things I am going to explain later on).

An **application** is a semantic group of pods. Pods may be communicating with each other, for example in a message-passing manner, to give the impression of a bigger application to the external user.

A **node** is a physical or virtual machine that hosts a running pod. In general, a deployment config declares the resources a pod needs that are allocated from the *cluster* to the node.

A **cluster** is a group of nodes. Nodes can have heterogeneous nature, for example some may have 0, 1 or more GPUs, 1 or more cores and so on. If you are using the Glasgow DCS cluster, well there's not much else to choose! Otherwise, in GCP you can choose which cluster to run your application on.

A **deployment** is the task of instructing kubernetes to setup a new application. To avoid confusion:

- A deployment configuration has a name and a namespace.

- Each deployment config sets up an application. Technically, an application does not have a name, however it must have at least a label which in general is used as an identifier.

- Each pod, in turn, has a name.

That means, in the most basic deployment config you'll have to come up with 3 different names. Your fantasy will drain out in a few seconds!

A **service** is "an abstract way to expose an application running on a set of pods as a service network". In a nutshell, pods have unstable ip addresses as they might day in any moment, and services make sure they are always load-balanced. Again:

- A service has a name

- A selector selects one or more pods that share a label with the same value

- A service maps an external port that you want to reach out to a target port that the pods should declare open.

A **route** (or ingress in kubernetes) usually is an API object that provides automatic HTTP proxing without manually configuring the pods to handle HTTP rewrite rules. To define a route, you need a service.

In Kubernetes pods are volatile and do not possess persistent storage by default. If a pod needs data to be stored, and does not use a database for that (or if the pod is the database itself :) ) then you need **persistent storage**. As with nodes, persistent storage is a subdivision of the total actually available storage. However, pods may share the storage by *claiming* its usage, i.e. by self-declaring an usage quota and a mount point.

### So what should I do?

In a nutshell, you need to:

- Get access to storage. In case of the DCS, your volume will be given by the administrator, otherwise you'll have to create it yourself called `nfs-access`.

- Choose a persistent storage claim. Again, in case of the DCS you'll be given a claim called `<youraccount>volxclaim`.

- Set up a deployment config which in turn will set up a pod for you. You should specify the storage and storage claim, along with the resources you need for the node.

- Then you setup a service and a route,

### Do I need serviceAccount set to containerroot ?

If you use a fairly maintained docker image taken from the hub, no. containerroot allows you to be root inside the container. If your image only sets up a root user it could be required. You should refrain from making your own docker images, and allowing root in them.
