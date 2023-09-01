# aws-fsxn-hybrid-shares-access

The terrraform code deploys an Amazon FSx for NetApp ONTAP filesystem, AD and VPN setup for quick access to shares to simulate on-prem access

![Architecture Diagram](/images/FSxN+ClientVPN.png)

##### Order of Deployment

- VPC
- 1 Public and 1 Private Subnet
- 1 Active Directory on EC2
  - The active directory configuration will include a Domain setup, Organization Unit (FSxN), a File System Administrators group, and a service account user
- 1 FSxN File System (1 SVM joined to AD and 3 volumes)
- 1 Client VPN Endpoint

##### Post Deployment

- Access the AD instance and create file shares
- Add additional users and assign share permissions if necessary
- Setup VPN Client (see the AWS Client VPN setup section)
- Connect to the VPN via OpenVPN Client and access the file shares using the SVM IP address

##### AWS Client VPN Setup

Open the Amazon VPC console at https://console.aws.amazon.com/vpc/.

In the navigation pane, choose Client VPN Endpoints.

Select the Client VPN endpoint that you created for this tutorial, and choose Download client configuration.

Locate the client certificate and key that were generated in Step 1. The client certificate and key can be found in the following locations in the cloned OpenVPN easy-rsa repo:

Note: The default certificates can be found under the .terraform/modules/vpn/certs or can be checked at https://github.com/varunrai/terraform-aws-clientvpn.git
These certs are pre-generated and should not be used for production deployment.
You may want to generate your own certificates for use with this setup and assign the variables of the VPN module in main.tf

```bash
Client certificate — easy-rsa/easyrsa3/pki/issued/client1.domain.tld.crt

Client key — easy-rsa/easyrsa3/pki/private/client1.domain.tld.key
```

Open the Client VPN endpoint configuration file using your preferred text editor. Add <cert></cert> and <key></key> tags to the file. Place the contents of the client certificate and the contents of the private key between the corresponding tags, as such:

```xml
<cert>
Contents of client certificate (.crt) file
</cert>

<key>
Contents of private key (.key) file
</key>
```

Locate the line that specifies the Client VPN endpoint DNS name, and prepend a random string to it so that the format is random_string.displayed_DNS_name. For example:

```
Original DNS name: cvpn-endpoint-0102bc4c2eEXAMPLE.prod.clientvpn.us-west-2.amazonaws.com

Modified DNS name: asdfa.cvpn-endpoint-0102bc4c2eEXAMPLE.prod.clientvpn.us-west-2.amazonaws.com
```

Note:
We recommend that you always use the DNS name provided for the Client VPN endpoint in your configuration file, as described. The IP addresses that the DNS name will resolve to are subject to change.

Save and close the Client VPN endpoint configuration file.

Distribute the Client VPN endpoint configuration file to your end users.

[Reference](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/cvpn-getting-started.html#cvpn-getting-started-config)
