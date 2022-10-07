ARG BASE_IMAGE="ubuntu"
ARG RELEASE_TAG="22.04"


FROM ${BASE_IMAGE}:${RELEASE_TAG}

ENV \
  DEBIAN_FRONTEND="noninteractive" \
  PYTHON_VERSION="3.8" \
  CONDA_DIR="/opt/conda" \
  TZ="UTC" \
  LC_ALL="en_US.UTF-8" \
  LANG="en_US.UTF-8" \
  LANGUAGE="en_US:en" \
  USER="docker" \
  PASSWORD="docker"

USER root


RUN apt-get update                                                               && \
    apt-get install -y --no-install-recommends                                      \
        build-essential                                                             \
        git                                                                         \
        curl                                                                        \
        ca-certificates                                                             \
        sudo                                                                        \
        locales                                                                     \
        openssh-server                                                              \
        vim                                                                      && \
    rm -rf /var/lib/apt/lists/*                                                  && \
    # Generate and Set locals
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen         && \
      locale-gen                                                                 && \
      dpkg-reconfigure --frontend=noninteractive locales                         && \
      update-locale LANG=${LANG}                                                 && \
    # Setup timezone
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone   && \
    ldconfig


# Install miniconda
# Referenced PyTorch's Dockerfile:
#   https://github.com/pytorch/pytorch/blob/master/Dockerfile
RUN curl -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh   && \
    chmod +x miniconda.sh                                                                        && \
    ./miniconda.sh -b -p ${CONDA_DIR}                                                            && \
    rm miniconda.sh                                                                              && \
    ${CONDA_DIR}/bin/conda install -y python=$PYTHON_VERSION jupyter jupyterlab                  && \
    touch $HOME/.bashrc                                                                          && \
    echo "export PATH=${CONDA_DIR}/bin:$PATH" >> /root/.bash_profile                             && \
    . /root/.bash_profile

# Install Jupyter extension
RUN \
  mkdir "${HOME}/app/"                            && \
  mkdir -p /root/.jupyter/custom                  && \
  ln -s app/custom /root/.jupyter/custom/custom   && \
  # jupyter nbextension install /app/extension/extend.js --sys-prefix && \
  jupyter nbextension enable extend --sys-prefix
  # jupyter nbextension enable extensions/extension --sys-prefix --section='common'
  # mv /root/.jupyter/custom.css /root/.jupyter/custom/custom.css


VOLUME [ "${HOME}/app/" ]

EXPOSE 8888

CMD ["/bin/bash"]

ENTRYPOINT [                                    \
  "jupyter", "notebook",                        \
    "--ip=0.0.0.0",                             \
    "--port=8888",                              \
    "--notebook-dir=app/",                      \
    "--config=/app/jupyter_notebook_config.py", \
    "--NotebookApp.token=''",                   \
    "--NotebookApp.password=''",                \
    "--no-browser",                             \
    "--autoreload",                             \
    "--allow-root"                              \
]
