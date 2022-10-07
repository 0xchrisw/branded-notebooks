ARG BASE_IMAGE="ubuntu"
ARG RELEASE_TAG="22.04"


FROM ${BASE_IMAGE}:${RELEASE_TAG}

# set pip's cache directory using this environment variable, and use
# ARG instead of ENV to ensure its only set when the image is built
ARG PIP_CACHE_DIR=/tmp/pip-cache

ENV DEBIAN_FRONTEND="noninteractive"   \
    PYTHON_VERSION="3.9"               \
    CONDA_DIR="/opt/conda"             \
    TZ="UTC"                           \
    LC_ALL="en_US.UTF-8"               \
    LANG="en_US.UTF-8"                 \
    LANGUAGE="en_US:en"                \
    PATH="/opt/conda/bin:$PATH"        \
    USER="docker"                      \
    PASSWORD="docker"

USER root

SHELL ["/bin/bash", "-c"]

RUN apt-get update                                                               && \
    apt-get install -y --no-install-recommends                                      \
      build-essential                                                               \
      git                                                                           \
      curl                                                                          \
      ca-certificates                                                               \
      locales                                                                       \
      openssh-server                                                                \
      # sudo                                                                        \
      vim                                                                        && \
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
RUN curl -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh   && \
    chmod +x miniconda.sh                                                                        && \
    ./miniconda.sh -b -p /opt/conda                                                              && \
    rm miniconda.sh                                                                              && \
    conda install -c conda-forge -n base nomkl mamba                                             && \
    mamba install -c conda-forge -n base python=3.9 jupyter jupyterlab                           && \
    ln -s /opt/conda/profile.d/conda.sh /etc/profile.d/conda.sh                                  && \
    conda init bash


# Install Jupyter extension
RUN mkdir "/app"                                    && \
    mkdir -p /root/.jupyter/custom                  && \
    ln -s app/custom /root/.jupyter/custom/custom   && \
    pip install jupyter_contrib_nbextensions        && \
    jupyter contrib nbextensions install
    # jupyter labextension link .
    # jupyter labextension install .
    # jupyter nbextension install /app/extension/extend.js --sys-prefix && \
    # jupyter nbextension enable extend --sys-prefix
    # mv /root/.jupyter/custom.css /root/.jupyter/custom/custom.css


VOLUME [ "/app" ]

EXPOSE 8888

ENTRYPOINT ["/bin/bash"]

CMD [                                           \
  "jupyter", "notebook",                        \
    "--ip=0.0.0.0",                             \
    "--port=8888",                              \
    "--notebook-dir=/app",                      \
    # "--config=/app/jupyter_notebook_config.py", \
    "--NotebookApp.token=''",                   \
    "--NotebookApp.password=''",                \
    "--no-browser",                             \
    "--autoreload",                             \
    "--allow-root",                             \
    "&"                                         \
]
