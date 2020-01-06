FROM centos:7

# Airflow
ARG AIRFLOW_VERSION=1.10.7
ARG AIRFLOW_HOME=/home/airflow/airflow
ARG AIRFLOW_PACKAGES=all

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV SLUGIFY_USES_TEXT_UNIDECODE yes
ENV CFLAGS -I/usr/include/libffi/include
ENV AIRFLOW_USER_HOME /home/airflow
ENV AIRFLOW_HOME ${AIRFLOW_USER_HOME}/airflow
ENV VIRTUAL_ENV ${AIRFLOW_USER_HOME}/venv

COPY ./script/entrypoint.sh /entrypoint.sh

RUN set -ex \
    && useradd -ms /bin/bash -d ${AIRFLOW_USER_HOME} airflow \
    && yum update -y \
    && curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/msprod.repo \
    && yum update -y \
    && ACCEPT_EULA=Y yum install -y msodbcsql17 mssql-tools \
    && yum makecache \
    && yum install -y epel-release \
    && yum makecache \    
    && yum install -y gcc \
    wget \
    unixODBC \
    unixODBC-devel \
    which \
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
    && mkdir ${AIRFLOW_HOME} \
    && chown -R airflow: ${AIRFLOW_HOME} \
    && chown -R airflow: /entrypoint.sh \
    && chmod 770 /entrypoint.sh \
    && pip3 install --upgrade pip \
    && pip install virtualenv

USER airflow

ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN python3 -m virtualenv --python=/usr/bin/python3 $VIRTUAL_ENV \
    && echo 'PATH="$VIRTUAL_ENV/bin:$PATH:/opt/mssql-tools/bin"' >> ${AIRFLOW_USER_HOME}/.bash_profile \
    && echo 'AIRFLOW_HOME=/home/airflow/airflow' >> ${AIRFLOW_USER_HOME}/.bash_profile \
    && pip install pytest-runner \
    && pip install "pymssql~=2.1" \
    && pip install apache-airflow[${AIRFLOW_PACKAGES}]==$AIRFLOW_VERSION \
    && pip install --upgrade jsonpatch

EXPOSE 8080 5555 8793

WORKDIR ${AIRFLOW_HOME}