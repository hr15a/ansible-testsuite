# Hint : this dockerfile provides image 'ansible/centos:remote-target'
FROM ansible/centos:remote-runner
MAINTAINER Hery Njato RANDRIAMANAMIHAGA <herynjato.randriamanamihaga@smile.fr>

# Install OpenSSH server for remote management
RUN yum install -y openssh-server                                         && \
    yum clean all                                                         && \
    su - ansible -c "cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys"
