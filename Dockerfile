FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:alpine

RUN gcloud components install alpha

COPY scripts /scripts
RUN chown -R 1000:root /scripts && chmod -R 775 /scripts

WORKDIR scripts
