# Hint : this dockerfile provides image 'ansible/centos:base'
FROM centos/systemd
MAINTAINER Hery Njato RANDRIAMANAMIHAGA <herynjato.randriamanamihaga@smile.fr>

# Install required packages
RUN yum install -y epel-release                                           && \
    yum update -y                                                         && \
    yum install -y ansible                                                   \
                   sudo                                                      \
                   iproute telnet                                            \
                   vim                                                       \
                   tree                                                      \
                   bash-completion bash-completion-extras                    \
    yum clean all                                                         && \
    rm -Rf /var/cache/yum                                                 && \
    echo "%wheel  ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers          && \
    useradd -ms /bin/bash ansible -G wheel

VOLUME [ “/sys/fs/cgroup” ]
ENTRYPOINT /usr/sbin/init
