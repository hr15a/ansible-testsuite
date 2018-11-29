# Hint : this dockerfile provides image 'ansible/centos:remote-${ANSIBLE_VERSION}-runner'

FROM ansible/centos:remote-runner
MAINTAINER Hery Njato RANDRIAMANAMIHAGA <herynjato.randriamanamihaga@smile.fr>
ARG ANSIBLE_VERSION=latest

# Install custom Ansible version using PIP
RUN yum install -y python-pip && yum clean all                            && \
    pip --no-cache-dir install -U pip                                     && \
    pip --no-cache-dir install ansible==${ANSIBLE_VERSION}
