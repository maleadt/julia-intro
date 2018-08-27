FROM jupyter/minimal-notebook:8ccdfc1da8d5


# install Julia

USER root

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
                    # tools
                    ca-certificates curl git \
                    # common package dependencies
                    build-essential gfortran && \
    apt-get clean && \
rm -rf /var/lib/apt/lists/*

ENV JULIA_VERSION=0.7.0
ENV JULIA_CHECKSUM=35211bb89b060bfffe81e590b8aeb8103f059815953337453f632db9d96c1bd6

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    echo "${JULIA_CHECKSUM} *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

# Show Julia where conda lives
ENV CONDA_JL_HOME /opt/conda
RUN mkdir /etc/julia && \
    echo "using Libdl" >> /etc/julia/startup.jl && \
    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/startup.jl


# add Julia packages

# install Julia packages in /opt/julia instead of $HOME
ENV JULIA_DEPOT_PATH=/opt/julia

RUN mkdir $JULIA_DEPOT_PATH && \
    chown $NB_USER $JULIA_DEPOT_PATH && \
    fix-permissions $JULIA_DEPOT_PATH

USER $NB_UID

# Install IJulia as jovyan and then move the kernelspec out
# to the system share location. Avoids problems with runtime UID change not
# taking effect properly on the .local folder in the jovyan home dir.
RUN julia -e 'using Pkg; \
              pkg"add IJulia"; \
              pkg"precompile";' && \
    # move kernelspec out of home \
    mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
    rm -rf $HOME/.local && \
    fix-permissions $JULIA_DEPOT_PATH $CONDA_DIR/share/jupyter
