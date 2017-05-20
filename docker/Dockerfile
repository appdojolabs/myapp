FROM ubuntu:16.04

# Avoid error messages from apt during image build
ARG DEBIAN_FRONTEND=noninteractive


RUN \
  apt-get update && \
  apt-get install -y wget curl

RUN \
  wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
  dpkg -i erlang-solutions_1.0_all.deb && \
  apt-get update && \
  apt-get install -y esl-erlang elixir build-essential openssh-server git locales

RUN \
  apt-get update && \
  curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
  apt-get install -y nodejs

# Elixir requires UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN update-locale LANG=$LANG

RUN mkdir /var/run/sshd

# Create Builder user
RUN useradd --system --shell=/bin/bash --create-home builder

#config builder user for public key authentication
RUN mkdir /home/builder/.ssh/ && chmod 700 /home/builder/.ssh/
COPY ./config/ssh_key.pub /home/builder/.ssh/authorized_keys
RUN chown -R builder /home/builder/
RUN chgrp -R builder /home/builder/
RUN chmod 700 /home/builder/.ssh/
RUN chmod 644 /home/builder/.ssh/authorized_keys


RUN mix local.hex
RUN mix local.rebar

#Configure public keys for sshd
RUN  echo "AuthorizedKeysFile  %h/.ssh/authorized_keys" >> /etc/ssh/sshd_config

RUN mkdir -p /home/builder/config
COPY config/prod.secret.exs /home/builder/config/prod.secret.exs

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
