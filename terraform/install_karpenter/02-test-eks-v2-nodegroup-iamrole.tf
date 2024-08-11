resource "aws_iam_role" "karpenter_instance_role" {
  name = "KarpenterNodeRole-${var.cluster_name}"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })
}

resource "aws_iam_role" "karpenter_controller_role" {
  name = "KarpenterControllerRole-${var.cluster_name}"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_arn}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_extract_from_arn}:aud": "sts.amazonaws.com",
                    "${data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_extract_from_arn}:sub": "system:serviceaccount:kube-system:karpenter"
                }
            }
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_instance_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter_AmazonEKSCNIPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_instance_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_instance_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.karpenter_instance_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter_CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.karpenter_instance_role.name
}
