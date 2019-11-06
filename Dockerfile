FROM centos:7

# Airflow
ARG AIRFLOW_VERSION=1.10.6
ARG AIRFLOW_HOME=/usr/local/airflow
ARG AIRFLOW_PACKAGES=all

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV SLUGIFY_USES_TEXT_UNIDECODE yes
ENV CFLAGS -I/usr/include/libffi/include
ENV AIRFLOW_HOME /usr/local/airflow

RUN useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow

COPY ./script/entrypoint.sh /entrypoint.sh

RUN set -ex \
    && yum update -y \
    && curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/msprod.repo\
    && yum update -y \
    && ACCEPT_EULA=Y yum install -y msodbcsql17 mssql-tools \
    && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /usr/local/airflow/.bash_profile \
    && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /usr/local/airflow/.bashrc \    
    && yum makecache \
    && yum install -y epel-release \
    && yum makecache \    
    && yum install -y gcc \
    wget \
    unixODBC \
    unixODBC-devel \
    jq \
    python-virtualenv \
    python3-pip \
    mysql-devel \
    python3-devel \
    python3 \
    krb5-devel \
    krb5-workstation \
    cyrus-sasl-devel \
    gdbm-devel \
    java-1.8.0-openjdk \
    postgresql-devel \
    nmap-ncat \
    gcc-c++ \
    && wget http://download.redis.io/redis-stable.tar.gz -O redis-stable.tar.gz \
    && tar xvzf redis-stable.tar.gz \
    && cd redis-stable/deps \
    && make hiredis jemalloc linenoise lua \
    && cd .. \
    && make \
    && cp src/redis-cli /usr/local/bin/ \
    && chmod 755 /usr/local/bin/redis-cli \
    && cd .. \
    && rm -rf redis-stable \
    && rm redis-stable.tar.gz \
    && echo 'export AIRFLOW_HOME=/usr/local/airflow' >> /usr/local/airflow/.bash_profile \
    && pip3 install pytest-runner \
    && pip3 install apache-airflow[${AIRFLOW_PACKAGES}]==$AIRFLOW_VERSION \
    && pip3 install --upgrade jsonpatch

RUN chown -R airflow: ${AIRFLOW_HOME} \
    && chown -R airflow: /entrypoint.sh \
    && chmod 770 /entrypoint.sh

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}