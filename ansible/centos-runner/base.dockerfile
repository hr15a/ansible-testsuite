FROM centos/systemd
MAINTAINER Hery Njato RANDRIAMANAMIHAGA <mogshooter@gmail.com>

# Install required packages
RUN yum install -y epel-release                                           && \
    yum update -y                                                         && \
    yum install -y ansible                                                   \
                   sudo                                                      \
                   iproute                                                && \
    yum clean all                                                         && \
    rm -Rf /var/cache/yum                                                 && \
    echo "%wheel  ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers          && \
    useradd -ms /bin/bash ansible -G wheel

VOLUME [ “/sys/fs/cgroup”, "/home/ansible" ]
ENTRYPOINT /usr/sbin/init
