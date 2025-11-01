# ----------------------------------------------------------
# 1. Create IAM Policy from local JSON file
# ----------------------------------------------------------
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "AWSLoadBalancerControllerNonEKS"
  description = "Policy for AWS Load Balancer Controller (non-EKS)"
  policy      = file("${path.module}/aws-load-balancer-controller-policy.json")
}

# ----------------------------------------------------------
# 2. Create IAM Role with Trust Policy
# ----------------------------------------------------------
resource "aws_iam_role" "alb_controller_role" {
  name               = "AWSLoadBalancerControllerRole"
  assume_role_policy = file("${path.module}/trust-policy.json")
}

# ----------------------------------------------------------
# 3. Attach the Policy to the Role
# ----------------------------------------------------------
resource "aws_iam_role_policy_attachment" "alb_controller_role_attach" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

# ----------------------------------------------------------
# 4. Create Instance Profile and Attach Role
# ----------------------------------------------------------
resource "aws_iam_instance_profile" "alb_controller_instance_profile" {
  name = "AWSLoadBalancerControllerInstanceProfile"
  role = aws_iam_role.alb_controller_role.name
}

