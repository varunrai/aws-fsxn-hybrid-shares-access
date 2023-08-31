# aws-fsxn-hybrid-shares-access

The terrraform code deploys an Amazon FSx for NetApp ONTAP filesystem, AD and VPN setup for quick access to shares to simulate on-prem access

![Architecture Diagram](/images/FSxN+ClientVPN.png)

##### Order of Deployment

- VPC
- 1 Public and 1 Private Subnet
- 1 Active Directory on EC2
- 1 FSxN File System (1 SVM joined to AD and 3 volumes)
- 1 Client VPN Endpoint
