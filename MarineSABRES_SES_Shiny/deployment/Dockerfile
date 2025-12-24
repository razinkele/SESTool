# Dockerfile for MarineSABRES SES Shiny Application
# Base image with R and Shiny Server
FROM rocker/shiny-verse:4.4.1

# Maintainer information
LABEL maintainer="MarineSABRES Team"
LABEL description="MarineSABRES Social-Ecological Systems Analysis Tool"
LABEL version="1.0"

# Set working directory
WORKDIR /srv/shiny-server/marinesabres

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c( \
    'shiny', \
    'shinydashboard', \
    'shinyWidgets', \
    'shinyjs', \
    'shinyBS', \
    'shiny.i18n', \
    'tidyverse', \
    'dplyr', \
    'tidyr', \
    'readr', \
    'purrr', \
    'tibble', \
    'stringr', \
    'forcats', \
    'lubridate', \
    'DT', \
    'openxlsx', \
    'jsonlite', \
    'digest', \
    'igraph', \
    'visNetwork', \
    'ggraph', \
    'tidygraph', \
    'ggplot2', \
    'plotly', \
    'dygraphs', \
    'xts', \
    'timevis', \
    'rmarkdown', \
    'htmlwidgets' \
    ), repos='https://cran.rstudio.com/')"

# Copy application files
COPY app.R /srv/shiny-server/marinesabres/
COPY global.R /srv/shiny-server/marinesabres/
COPY run_app.R /srv/shiny-server/marinesabres/
COPY constants.R /srv/shiny-server/marinesabres/
COPY io.R /srv/shiny-server/marinesabres/
COPY utils.R /srv/shiny-server/marinesabres/
COPY VERSION /srv/shiny-server/marinesabres/
COPY VERSION_INFO.json /srv/shiny-server/marinesabres/
COPY version_manager.R /srv/shiny-server/marinesabres/
COPY modules/ /srv/shiny-server/marinesabres/modules/
COPY functions/ /srv/shiny-server/marinesabres/functions/
COPY scripts/ /srv/shiny-server/marinesabres/scripts/
COPY server/ /srv/shiny-server/marinesabres/server/
COPY www/ /srv/shiny-server/marinesabres/www/
COPY data/ /srv/shiny-server/marinesabres/data/
COPY translations/ /srv/shiny-server/marinesabres/translations/
COPY docs/ /srv/shiny-server/marinesabres/docs/

# Set permissions
RUN chown -R shiny:shiny /srv/shiny-server/marinesabres

# Expose port 3838
EXPOSE 3838

# Run Shiny Server
CMD ["/usr/bin/shiny-server"]
