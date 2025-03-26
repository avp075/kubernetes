
# Single Node Openshift on AWS

```
Creating and configuring the Route 53 service
Creating the IAM user
Create AWS instance
login to aws ec2 instance
ssh-keygen -t ed25519 -N '' -f ${HOME}/.ssh/ocp4-aws-key
cat ${HOME}/.ssh/ocp4-aws-key.pub
https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.15.8/openshift-client-linux-4.15.8.tar.gz
https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.15.8/openshift-install-linux-4.15.8.tar.gz
tar -xvf openshift-client-linux-4.15.8.tar.gz
tar -xvf openshift-install-linux-4.15.8.tar.gz
sudo mv oc kubectl /usr/local/bin
sudo mv openshift-install /usr/local/bin
openshift-install version
openshift-install create install-config --dir=./


```
```
 compute:
           - architecture: amd64
             hyperthreading: Enabled
             name: worker
             platform: {}
             replicas: 0
           controlPlane:
             architecture: amd64
             hyperthreading: Enabled
             name: master
             platform: {}
             replicas: 1
```
`openshift-install create cluster --dir=./ --log-level=debug`
