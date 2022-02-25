FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04


ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install basic applications
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated \
    openssh-server vim nano htop tmux sudo git git-gui unzip build-essential \
    openmpi-bin bash-completion \
    libsm6 libxext6 pkg-config unzip wget less tzdata zlib1g-dev \
    libjpeg8-dev libtiff5-dev libpng-dev bzip2 git libarchive-tools \
    libncurses5-dev libncursesw5-dev \
    cron direnv \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    bash-completion \
    libgtk2.0-dev \
    software-properties-common \
    ninja-build \
    openjdk-11-jdk \
    mosh \
    cmake \
    libwebp-dev \
    # Codec for OpenCV
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev \
    # Optimize for OpenCV
    libatlas-base-dev gfortran

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -  && \
    export DEBIAN_FRONTEND=noninteractive && \
    add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"  && \
    apt-get update && \
    apt-get install -y docker-ce-cli

# Install Cmake Latest version
RUN wget --quiet https://github.com/Kitware/CMake/releases/download/v3.18.2/cmake-3.18.2-Linux-x86_64.sh  \
        -O /tmp/cmake-install.sh && \
    chmod +x /tmp/cmake-install.sh && \
    /tmp/cmake-install.sh --skip-license --prefix=/usr/local

# Set the timezone
RUN echo "Asia/Seoul" | tee /etc/timezone && \
    ln -fs /usr/share/zoneinfo/Asia/Seoul /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata    

# Install Default Python ML Environment via Conda
ENV CONDA_DIR=/usr/local
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py37_4.9.2-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -u -p /usr/local && \
    rm ~/miniconda.sh \
    && ln -fs ${CONDA_DIR}/bin/pip ${CONDA_DIR}/bin/pip3
RUN ${CONDA_DIR}/bin/conda install numba cython numpy mkl mkl-include setuptools \
      scipy scikit-learn pandas matplotlib \
      jupyterlab jupyter \
    && pip install torch==1.10.0+cu113 torchvision==0.11.1+cu113 torchaudio==0.10.0+cu113 \
    dlib==19.22.0 dropblock==0.3.0 resnest==0.0.5 -f https://download.pytorch.org/whl/torch_stable.html

# Install Default Python ML Environment via Pip
RUN pip install gitpython sagemaker tensorboardX

# Copy OpenCV
COPY --from=res-env/opencv /output /usr/local
COPY --from=res-env/opencv /usr/local/lib/python3.7/site-packages/cv2 /usr/local/lib/python3.7/site-packages/cv2

# Re Install Pillow from pil with webp support
RUN pip uninstall -y pillow \
    && pip install "Pillow>=8.0.1,<9.0"

# Protobuf python
RUN cd /tmp && \
    wget -q https://github.com/protocolbuffers/protobuf/releases/download/v3.13.0/protobuf-python-3.13.0.tar.gz && \
    tar -xf protobuf-python-3.13.0.tar.gz && \
    cd /tmp/protobuf-3.13.0 && ./configure && \
    make -j8 install && cd python \
    && python3 setup.py install

# Setup jupyter lab & Notebook
RUN jupyter serverextension enable --py jupyterlab --sys-prefix

# Jupyter visualization extension
RUN cd /usr/local/share && git clone https://github.com/PAIR-code/facets && \
    cd facets && jupyter nbextension install facets-dist/

# Install utility packages
RUN pip install torchserve torch-model-archiver && \
    pip install supervisor pipenv && \
    pip install boto3

# Install code-server 
ENV CODE_SERVER_VERSION 3.10.2
RUN cd /tmp && wget --quiet --no-check-certificate https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server_${CODE_SERVER_VERSION}_amd64.deb && \
    dpkg -i code-server_${CODE_SERVER_VERSION}_amd64.deb && \
    rm -rf code-server_${CODE_SERVER_VERSION}_amd64.deb

# SSHD Option
RUN mkdir -p /var/run/sshd && \
    # SSH login fix. Otherwise user is kicked off after login
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo "AddressFamily inet" >> /etc/ssh/sshd_config

# Make user
RUN groupadd --gid 999 docker && \
    useradd -ms /bin/bash -d /home/omnious -G sudo,staff,docker omnious && \
    echo "omnious ALL=NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir -p /home/omnious/.ssh && chown omnious:omnious /home/omnious/.ssh

# Supervisord Options
RUN mkdir -p /var/log/supervisor && \
    mkdir -p /srv/runscript

COPY supervisord/run-jupyter-lab.sh /srv/runscript/run-jupyter-lab.sh
COPY supervisord/run-jupyter-notebook.sh /srv/runscript/run-jupyter-notebook.sh
COPY supervisord/supervisord.conf /etc/supervisord.conf
COPY --chown=omnious:omnious ssh-key/docker-env.pub /home/omnious/.ssh/authorized_keys
RUN chmod +x /srv/runscript/*.sh \
    && chmod 600 /home/omnious/.ssh/authorized_keys

# Start point
COPY ./supervisord/start.sh /usr/local/bin/start
RUN chmod +x /usr/local/bin/start

EXPOSE 22 8800 8801 6003 6004 6005 6006 6007 6008 6009 6010
CMD ["start"]
