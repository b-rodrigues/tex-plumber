###########################
# Builder image
###########################
FROM debian:buster-20210511 AS builder

ENV V_RStudio=R-4.1.0
ENV V_ShinyServer=v1.5.16.958

RUN apt-get update && apt-get install -y \
    gfortran libreadline6-dev libx11-dev libxt-dev \
    libpng-dev libjpeg-dev libcairo2-dev xvfb libbz2-dev \
    libzstd-dev liblzma-dev libcurl4-openssl-dev \
    texinfo texlive texlive-fonts-extra screen wget libpcre2-dev \
    git apt-utils sed make cmake g++ default-jdk 

#Install R with blas and lapack support. Remove '--with-blas --with-lapack' to disable
WORKDIR /usr/local/src
RUN wget https://cran.rstudio.com/src/base/R-4/${V_RStudio}.tar.gz && \
    tar zxvf ${V_RStudio}.tar.gz && \
    cd /usr/local/src/${V_RStudio} && \
    ./configure --enable-R-shlib --with-blas --with-lapack && \
    make -j4 && \
    make -j4 install && \
    cd /usr/local/src/ && \
    rm -rf ${V_RStudio}*

#Set python3 as the default python
RUN rm /usr/bin/python && \
    ln -s /usr/bin/python3 /usr/bin/python

###########################
# Production image
###########################
FROM debian:buster-20210511
#Copy artefacts from builder image
COPY --from=builder /usr/local/bin/R /usr/local/bin/R
COPY --from=builder /usr/local/lib/R /usr/local/lib/R
COPY --from=builder /usr/local/bin/Rscript /usr/local/bin/Rscript

#Create folder structure and set permissions
WORKDIR /
RUN mkdir -p        /srv/plumber     && \
    chmod -R 777    /srv/plumber

RUN apt-get update && apt-get install -y \
    gfortran libreadline6-dev libsodium-dev \
    git-core libssl-dev libcurl4-gnutls-dev curl \
    libcairo2-dev xvfb libx11-dev libxt-dev libpng-dev libgpgme11-dev pandoc libghc-pandoc-dev pandoc-citeproc \
    libjpeg-dev libbz2-dev libzstd-dev liblzma-dev libatomic1 texlive-full libmagick++-dev \
    libgomp1 libpcre2-8-0 libssl-dev libxml2-dev g++ make && \
    rm -rf /var/lib/apt/lists/*

RUN Rscript -e "install.packages(c('plumber', 'dplyr', 'purrr', 'rmarkdown', 'bookdown', 'bookdownplus', 'gpg'), repos='http://cran.rstudio.com/', clean = TRUE)"

EXPOSE 8000
ENTRYPOINT ["R", "-e", "pr <- plumber::plumb(rev(commandArgs())[1]); args <- list(host = '0.0.0.0', port = 8000); if (packageVersion('plumber') >= '1.0.0') { pr$setDocs(TRUE) } else { args$swagger <- TRUE }; do.call(pr$run, args)"]

# Copy installed example to default file at ~/plumber.R
#ARG ENTRYPOINT_FILE=/usr/local/lib/R/library/plumber/plumber/04-mean-sum/plumber.R
#RUN cp ${ENTRYPOINT_FILE} /srv/plumber/plumber.R

CMD ["/srv/plumber/plumber.R"]

