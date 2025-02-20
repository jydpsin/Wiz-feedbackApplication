# Node.js Customer Feedback Application Deployment on AWS EKS

This guide explains how to deploy a Node.js application on an AWS EKS instance and integrate it with MongoDB on AWS EC2 using Terraform.

## Prerequisites

1. **AWS Account:** Ensure you have an AWS account. If not, [create one here](https://aws.amazon.com/).
2. **AWS Secret Manager:** To store secret keys with security

## Steps to run

1. **Run Your Application:**
   ```bash
   npm install
   AWS Configure
   npm start 
   teeraform init
   teraform plan
   terraform apply 
   ```
2. **Set Your secrets:** Set my-app-secret in Amazon Secret Manager
3. **Access Your Application locally:** Open a web browser and navigate to `http://localhost:<PORT>` to see your running application.
4. **Access Your Application on internet:** Open a web browser and navigate to `https://<elb_url>:<PORT>` to see your running application.

## Conclusion

You’ve successfully deployed your Node.js application on AWS EKS and integrated it with MongoDB which is residing on another EC2 in same network. Your application should now be running and connected to a cloud-based MongoDB database.

For more information, refer to the [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/index.html)
For more information, refer to the [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
For more information, refer to the [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)