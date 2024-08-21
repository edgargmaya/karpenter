Karpenter: Advanced Cluster Autoscaling



Introduction


Autoscaling is a critical aspect of Kubernetes, allowing clusters to dynamically adjust resources based on demand. This ability to automatically adjust the infrastructure to match demand is crucial for maintaining performance and optimizing costs.
However, is not an easy task, and there a lot of things happening under the hood in order to achieve this feature, this is where autoscalers come into play.

Autoscalers are tools designed to dynamically adjust the number of compute resources (such as virtual machines or containers) in response to varying workloads. In a Kubernetes environment, autoscalers play a vital role by ensuring that clusters have the
necessary amount of resources available at any given time. This not only helps in maintaining the efficiency of the applications running on the cluster but also in optimizing operational costs by scaling down resources during periods of low demand.

There are several types of autoscalers within Kubernetes:

Horizontal Pod Autoscaler (HPA):
Automatically scales the number of pods in a deployment or replica set based on observed CPU utilization, memory usage, or custom metrics.

Vertical Pod Autoscaler (VPA):
Adjusts the resource requests and limits of containers within pods based on their actual usage, ensuring that each pod has the resources it needs to perform optimally.

Cluster Autoscaler:
Adjusts the number of nodes in a cluster based on the pending pods that cannot be scheduled due to insufficient resources.

Among these, the Cluster Autoscaler is particularly critical because it directly manages the infrastructure by scaling the nodes themselves. Traditionally, the Cluster Autoscaler in Kubernetes has been responsible for adding and removing nodes
from the cluster based on the resource needs of the workloads. It’s a well-established tool that has been widely adopted for managing node resources efficiently.

However, as Kubernetes environments have grown more complex, the limitations of the traditional Cluster Autoscaler have become more apparent. It often struggles with the complexities of modern cloud environments, where the demand for rapid
scaling, cost optimization, and support for diverse workloads requires a more advanced solution. Cluster Autoscaler needs to talk and interact with Cloud APIs for creating/deleting resources with specific configurations such as Security profiles,
specific networking, run scripts during bootstraping process and many many more.

AWS, one of the most important Cloud providers is aware of all this, and have created Karpenter, an open-source, flexible, and efficient cluster autoscaler designed to address the challenges of modern cloud-native environments like the
already mentioned above.



Advantages of Karpenter

Karpenter introduces several key advantages over traditional autoscaling tools:

Flexibility:
Karpenter is designed to be cloud-agnostic, meaning it can work across different cloud providers, making it a versatile choice for multi-cloud environments.

Fast Scaling:
Unlike traditional autoscalers, which may take several minutes to provision new nodes, Karpenter is optimized for rapid scaling, reducing the time it takes to respond to changing workloads.

Cost Efficiency:
By integrating closely with cloud provider APIs, Karpenter can optimize the selection of instance types and sizes, leading to more cost-efficient scaling. It can also take advantage of spot instances to further reduce costs.

Customizable:
Karpenter allows for fine-grained control over node provisioning, enabling the use of custom node configurations to meet specific workload requirements.

Node Consolidation:
Karpenter includes features to automatically consolidate workloads onto fewer nodes when possible, reducing the number of underutilized instances and further optimizing costs.


How Karpenter Works at a Low Level
At a low level, Karpenter operates by interacting directly with the Kubernetes API and cloud provider APIs to monitor resource usage and provision nodes as needed. Here’s a breakdown of its operation:

1) Resource Monitoring:
Karpenter continuously monitors the resource demands of pods running in the cluster. When it detects that a pod cannot be scheduled due to insufficient resources, it triggers the provisioning of new nodes.

2) Node Provisioning:
3) Karpenter communicates with the cloud provider to select the most appropriate instance type based on the current demand. This selection process takes into account factors such as cost, availability, and performance.

3) Node Registration:
Once a new node is provisioned, it is automatically registered with the Kubernetes API server. Karpenter ensures that the node is configured correctly, with the necessary labels and taints, before allowing pods to be scheduled on it.

4) Node Termination:
Karpenter also manages the termination of nodes that are no longer needed. It uses observability in combination with advance algorithms to determine when a node can be safely terminated without impacting the workloads running in the cluster.

5) Spot Instance Management:
Karpenter can be configured to use spot instances, taking advantage of their lower cost. It automatically handles the complexities of spot instance interruptions by ensuring that workloads are rescheduled onto other nodes when needed.



Comparison with Traditional Cluster Autoscaler
While the traditional Kubernetes Cluster Autoscaler has served the community well, Karpenter brings several enhancements that make it a compelling alternative:

Speed: Traditional autoscalers can take several minutes to react to changes in demand due to their reliance on scaling groups and static configurations. Karpenter, on the other hand, provisions nodes much faster by interacting directly with cloud APIs.

Instance Flexibility: The traditional Cluster Autoscaler typically relies on predefined instance types and sizes within an autoscaling group. Karpenter dynamically selects the most appropriate instance based on real-time demand, leading to more efficient resource utilization.

Spot Instances: While the traditional autoscaler can use spot instances, Karpenter’s advanced spot instance management capabilities make it more adept at handling the complexities of spot instance interruptions and migrations.

Custom Node Configurations: Karpenter allows for more granular control over node configurations, including the ability to define custom AMIs, labels, and taints, which are not as easily managed with the traditional autoscaler.

Multi-Cloud Support: While the traditional autoscaler is often tied to specific cloud providers, Karpenter’s cloud-agnostic design makes it a better choice for multi-cloud environments.

When to Choose Karpenter Over Traditional Autoscaling
Karpenter is particularly useful in scenarios where rapid scaling, cost optimization, and advanced configuration are priorities. If your workloads are dynamic and require frequent scaling with minimal delay,
Karpenter is likely to outperform traditional autoscalers. Additionally, if your infrastructure spans multiple cloud providers or relies heavily on spot instances, Karpenter’s flexibility and advanced management
features will provide significant benefits.


NodePool.yaml
The NodePool.yaml file is where you define the criteria for the nodes that Karpenter will provision. This file is essential because it allows you to specify the characteristics and constraints that nodes should have
to meet the needs of specific workloads.
Using this file Karpenter knows thw nodes it will provision. This includes specifying the labels, taints, and resource requirements that Karpenter uses to determine which nodes to provision.
The NodePool.yaml file is essential for ensuring that the nodes match the specific needs of your workloads. For example, you can define which instance types should be used for different
environments (e.g., development vs. production), or which nodes should be tainted to ensure certain workloads are isolated.

One of the key advantages of Karpenter is that you can define multiple NodePool.yaml files, each tailored to different types of workloads or environments. For example, you might have one NodePool optimized for compute-intensive workloads,
another for memory-intensive applications, and yet another for general-purpose workloads. By defining multiple NodePools, you can ensure that each workload gets the right type of compute power, leading to better resource utilization and cost
efficiency.

Example: Defining a NodePool for Compute-Intensive Workloads

apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: compute-intensive
spec:
  requirements:
    - key: "kubernetes.io/arch"
      operator: In
      values: ["amd64", "arm64"]
    - key: "karpenter.sh/capacity-type"
      operator: In
      values: ["on-demand"]
    - key: "node.kubernetes.io/instance-type"
      operator: In
      values: ["c5.large", "c5.xlarge"]
  provider:
    instanceProfile: "KarpenterNodeInstanceProfile"
    subnetSelector:
      karpenter.sh/discovery: my-cluster
    securityGroupSelector:
      karpenter.sh/discovery: my-cluster
  limits:
    resources:
      cpu: "500"
      memory: "1000Gi"
  ttlSecondsAfterEmpty: 60


Multiple NodePools:
You can create multiple NodePool.yaml files, each defining different types of nodes. This allows you to design a robust architecture where different workloads are automatically scheduled onto the most appropriate nodes.

Requirements:
In the previous example, we specify that the nodes should be of certain instance types (c5.large, c5.xlarge) that are optimized for compute-intensive tasks. This ensures that when compute-heavy workloads need to be scheduled,
Karpenter provisions nodes that are best suited for them.

TTL and Limits:
The ttlSecondsAfterEmpty parameter ensures that nodes are terminated if they are empty for a specified duration, reducing costs by removing idle resources. Additionally, the limits section ensures that the NodePool only scales to a certain level,
preventing over-provisioning.



Example: Defining a NodePool for Spot Instances

apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: spot-instances
spec:
  requirements:
    - key: "kubernetes.io/arch"
      operator: In
      values: ["amd64"]
    - key: "karpenter.sh/capacity-type"
      operator: In
      values: ["spot"]
  provider:
    instanceProfile: "KarpenterNodeInstanceProfile"
    subnetSelector:
      karpenter.sh/discovery: my-cluster
    securityGroupSelector:
      karpenter.sh/discovery: my-cluster
  ttlSecondsAfterEmpty: 120
  consolidation:
    enabled: true


Spot Instances:
This NodePool.yaml example is configured to provision spot instances, which are cost-effective but can be interrupted by AWS. This is ideal for workloads that are fault-tolerant and can handle interruptions.

Consolidation:
The consolidation feature is enabled, allowing Karpenter to intelligently consolidate workloads onto fewer nodes when possible. This further optimizes cost and resource utilization by reducing the number of underutilized nodes.



EC2NodeClass.yaml
The EC2NodeClass.yaml file is where you define the specifics of the EC2 instances that Karpenter will provision. This includes details such as the AMI ID, instance type, and other EC2-specific configurations.
This file gives you granular control over the infrastructure that Karpenter uses, allowing you to optimize for cost, performance, or other factors relevant to your workloads.

Importance of These Files
Both NodePool.yaml and EC2NodeClass.yaml are critical for tailoring Karpenter’s behavior to your specific needs.
By carefully configuring these files, you can ensure that your cluster scales efficiently, meets the demands of your applications, and aligns with your cost and performance goals.
