# docker/Dockerfile
FROM rocker/shiny

WORKDIR /app

COPY app/R/00_deps.R /app/R/00_deps.R
RUN R -e "source('/app/R/00_deps.R')"

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/app', host='0.0.0.0', port=3838)"]
