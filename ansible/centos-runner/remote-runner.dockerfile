# Hint : this dockerfile provides image 'ansible/centos:remote-runner'
FROM ansible/centos:base
MAINTAINER Hery Njato RANDRIAMANAMIHAGA <herynjato.randriamanamihaga@smile.fr>

# Generate SSH keypair

RUN yum -y install openssh                                          && \
    yum clean all                                                   && \
    su - ansible -c "ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa"
