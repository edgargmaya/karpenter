#!/bin/bash

CLUSTER_NAME="edgar-test"
AWS_REGION="us-east-1"
KARPENTER_VERSION="0.37.0"
KARPENTER_NAMESPACE="kube-system"

for NODEGROUP in $(aws eks list-nodegroups --cluster-name "${CLUSTER_NAME}" --query 'nodegroups' --output text --region "${AWS_REGION}"); do
    aws ec2 create-tags --region "${AWS_REGION}" \
        --tags "Key=karpenter.sh/discovery,Value=${CLUSTER_NAME}" \
        --resources $(aws eks describe-nodegroup --cluster-name "${CLUSTER_NAME}" \
        --nodegroup-name "${NODEGROUP}" --query 'nodegroup.subnets' --output text --region "${AWS_REGION}")
done

NODEGROUP=$(aws eks list-nodegroups --cluster-name "${CLUSTER_NAME}" \
    --query 'nodegroups[0]' --output text --region "${AWS_REGION}")

LAUNCH_TEMPLATE=$(aws eks describe-nodegroup --cluster-name "${CLUSTER_NAME}" --region "${AWS_REGION}" \
    --nodegroup-name "${NODEGROUP}" --query 'nodegroup.launchTemplate.{id:id,version:version}' \
    --output text | tr -s "\t" ",")

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text --region "${AWS_REGION}")

echo $NODEGROUP
echo $LAUNCH_TEMPLATE
echo $AWS_ACCOUNT_ID

SECURITY_GROUPS=$(aws eks describe-cluster \
    --name "${CLUSTER_NAME}" --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text --region "${AWS_REGION}")

aws ec2 create-tags \
    --tags "Key=karpenter.sh/discovery,Value=${CLUSTER_NAME}" \
    --resources "${SECURITY_GROUPS}" --region "${AWS_REGION}"

OUTPUT_AWS_AUTH=$(cat <<EOF
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}
      username: system:node:{{EC2PrivateDNSName}}
EOF
)

# PRINT OUTPUT FOR CONFIGURING aws-auth.yaml
echo "$OUTPUT_AWS_AUTH"

helm template karpenter oci://public.ecr.aws/karpenter/karpenter --version "${KARPENTER_VERSION}" --namespace "${KARPENTER_NAMESPACE}" \
    --set "settings.clusterName=${CLUSTER_NAME}" \
    --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterControllerRole-${CLUSTER_NAME}" \
    --set controller.resources.requests.cpu=1 \
    --set controller.resources.requests.memory=1Gi \
    --set controller.resources.limits.cpu=1 \
    --set controller.resources.limits.memory=1Gi > karpenter.yaml

YAML_FILE="karpenter.yaml"

FRAGMENT="                operator: DoesNotExist"

TEXT_TO_INSERT=$(cat <<EOF
          - key: eks.amazonaws.com/nodegroup
            operator: In
            values:
            - ${NODEGROUP}
EOF
)

sed -i "/$FRAGMENT/ a\\
$(echo "$TEXT_TO_INSERT" | sed 's/$/\\/' | sed 's/^/    /')
" "$YAML_FILE"

kubectl create -f "https://raw.githubusercontent.com/aws/karpenter-provider-aws/main/pkg/apis/crds/karpenter.sh_nodepools.yaml"
kubectl create -f "https://raw.githubusercontent.com/aws/karpenter-provider-aws/main/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml"
kubectl create -f "https://raw.githubusercontent.com/aws/karpenter-provider-aws/main/pkg/apis/crds/karpenter.sh_nodeclaims.yaml"

# kubectl apply -f karpenter.yaml
