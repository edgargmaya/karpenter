#!/bin/bash

################################################################
# PREPARE SCRIPT
rm -r ./terraform/install_cluster/.terraform
rm ./terraform/install_cluster/.terraform.lock.hcl

rm -r ./terraform/install_autoscaler/.terraform
rm ./terraform/install_autoscaler/.terraform.lock.hcl

rm -r ./terraform/install_karpenter/.terraform
rm ./terraform/install_karpenter/.terraform.lock.hcl

################################################################
# PRE-CONFIGURE THE S3 BUCKET TO USE AS A BACKEND
export BUCKET_NAME="terraform-state-edgar-test-2"
export REGION="us-east-1"

aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION

if [ $? -eq 0 ]; then
  echo "Bucket '$BUCKET_NAME' creado exitosamente en la región '$REGION'."
else
  echo "Error al crear el bucket '$BUCKET_NAME'."
  exit 0
fi

################################################################
# PRE-CONFIGURE THE SUBNETS
FILTERS="Name=availabilityZone,Values=us-east-1a,us-east-1b,us-east-1c,us-east-1d"

subnets=$(aws ec2 describe-subnets --region $REGION --filters $FILTERS --query 'Subnets[*].SubnetId' --output text)

subnets_array=($subnets)

if [ ${#subnets_array[@]} -lt 2 ]; then
  echo "Error: No hay suficientes subnets disponibles en la región $REGION."
  exit 1
fi

subnet_1=${subnets_array[$RANDOM % ${#subnets_array[@]}]}
subnet_2=${subnets_array[$RANDOM % ${#subnets_array[@]}]}

while [ "$subnet_1" == "$subnet_2" ]; do
  subnet_2=${subnets_array[$RANDOM % ${#subnets_array[@]}]}
done

aws_account_id=$(aws sts get-caller-identity --query "Account" --output text --region "${REGION}")

export TF_VAR_subnet_1=$subnet_1
export TF_VAR_subnet_2=$subnet_2
export TF_VAR_aws_account_id=$aws_account_id

echo "export TF_VAR_subnet_1=\"$TF_VAR_subnet_1\""
echo "export TF_VAR_subnet_2=\"$TF_VAR_subnet_2\""
echo "export TF_VAR_aws_account_id=\"$aws_account_id\""

export TF_VAR_default_vpc=$(aws ec2 describe-vpcs --region us-east-1 --query 'Vpcs[?IsDefault==`true`].VpcId' --output text)
export TF_VAR_db_subnet_group_name$(aws rds describe-db-subnet-groups --region us-east-1 --query 'DBSubnetGroups[*].DBSubnetGroupName' --output text)

################################################################
# INSTALL K8S CLUSTER
cd terraform/install_cluster

terraform init
terraform apply --auto-approve

# INSTALL K8S AUTOESCALER
# cd ../install_autoscaler

# terraform init
# terraform apply --auto-approve

# INSTALL KARPENTER AUTOESCALER
cd ../install_karpenter

terraform init
terraform apply --auto-approve

#CONFIGURE KUBECTL
aws eks update-kubeconfig --region $REGION --name edgar-test

#INSTALL MONITORING
cd ../..
kubectl create ns monitoring

helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --namespace kube-system
sleep 40

# kubectl create ns kafka
# helm install strimzi-kafka-operator strimzi/strimzi-kafka-operator --namespace kafka
# sleep 100

# kubectl apply -f kafka/kafka.yaml
# sleep 45

# kubectl apply -f kafka/topic.yaml
# sleep 40

# helm install kafka-exporter prometheus-community/prometheus-kafka-exporter -n kafka -f kafka/exporter.yaml
# sleep 40

# helm install keda kedacore/keda --namespace keda --create-namespace
# sleep 30

# helm install prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring -f kafka/prometheus-values.yaml
# sleep 5
# helm install prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring -f kafka/prometheus-values.yaml
# sleep 50

# kubectl apply -f kafka/service-monitor.yaml