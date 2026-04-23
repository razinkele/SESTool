# Dockerfile for MarineSABRES SES Shiny Application
# Base image with R and Shiny Server
FROM rocker/shiny-verse:4.4.1

# Maintainer information
LABEL maintainer="MarineSABRES Team"
LABEL description="MarineSABRES Social-Ecological Systems Analysis Tool"
LABEL version="1.11.2"

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
    libicu-dev \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Install R packages (core dependencies)
RUN R -e "install.packages(c( \
    'shiny', \
    'bs4Dash', \
    'shinyWidgets', \
    'shinyjs', \
    'shinyBS', \
    'shinyFiles', \
    'shiny.i18n', \
    'tidyverse', \
    'dplyr', \
    'tidyr', \
    'readr', \
    'purrr', \
    'tibble', \
    'stringr', \
    'stringi', \
    'forcats', \
    'lubridate', \
    'magrittr', \
    'DT', \
    'openxlsx', \
    'readxl', \
    'jsonlite', \
    'digest', \
    'zoo', \
    'knitr', \
    'igraph', \
    'visNetwork', \
    'ggraph', \
    'tidygraph', \
    'ggplot2', \
    'plotly', \
    'dygraphs', \
    'xts', \
    'rmarkdown', \
    'htmlwidgets', \
    'htmltools', \
    'httr', \
    'officer', \
    'flextable', \
    'tinytex' \
    ), repos='https://cran.rstudio.com/')"

# Install TinyTeX LaTeX distribution for PDF export
RUN R -e "tinytex::install_tinytex()"

# Optional: Install torch for ML features (comment out if not needed)
# RUN R -e "install.packages('torch', repos='https://cran.rstudio.com/')"
# RUN R -e "torch::install_torch()"

# Copy application files (core)
COPY app.R /srv/shiny-server/marinesabres/
COPY global.R /srv/shiny-server/marinesabres/
COPY run_app.R /srv/shiny-server/marinesabres/
COPY constants.R /srv/shiny-server/marinesabres/
COPY utils.R /srv/shiny-server/marinesabres/
COPY VERSION /srv/shiny-server/marinesabres/
COPY VERSION_INFO.json /srv/shiny-server/marinesabres/
COPY version_manager.R /srv/shiny-server/marinesabres/

# Copy application directories (required)
COPY modules/ /srv/shiny-server/marinesabres/modules/
COPY functions/ /srv/shiny-server/marinesabres/functions/
COPY server/ /srv/shiny-server/marinesabres/server/
COPY www/ /srv/shiny-server/marinesabres/www/
COPY data/ /srv/shiny-server/marinesabres/data/
COPY translations/ /srv/shiny-server/marinesabres/translations/
COPY config/ /srv/shiny-server/marinesabres/config/

# Copy optional directories (documentation)
COPY docs/ /srv/shiny-server/marinesabres/docs/

# Copy SES Models directory (pre-built Excel models)
# Comment out if not needed in deployment
COPY SESModels/ /srv/shiny-server/marinesabres/SESModels/

# Copy ML models directory (optional - only if ML is enabled)
# Uncomment if using ML features
# COPY models/ /srv/shiny-server/marinesabres/models/

# Note: scripts/ is development-only — the runtime does not need any scripts.
# The old reverse_key_mapping.json reference was removed in Sprint 4 (M3) after
# Sprint 1 replaced the R-script i18n validator with scripts/_i18n_audit.py.

# Set permissions
RUN chown -R shiny:shiny /srv/shiny-server/marinesabres

# Expose port 3838
EXPOSE 3838

# Run Shiny Server
CMD ["/usr/bin/shiny-server"]
