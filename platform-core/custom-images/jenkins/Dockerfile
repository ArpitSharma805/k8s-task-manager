FROM docker.io/jenkins/jenkins:2.580.2-jdk25

USER root

# Basic packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    podman \
    && rm -rf /var/lib/apt/lists/*

# Dell corporate CA
COPY DellRoot2018.cer /tmp/DellRoot2018.cer
COPY DellRoot2018.cer /usr/local/share/ca-certificates/DellRoot2018.crt

RUN update-ca-certificates

RUN keytool -importcert \
    -alias dellroot2018 \
    -file /tmp/DellRoot2018.cer \
    -keystore /opt/java/openjdk/lib/security/cacerts \
    -storepass changeit \
    -noprompt

# Trivy
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
    gpg --dearmor -o /usr/share/keyrings/trivy.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
    > /etc/apt/sources.list.d/trivy.list && \
    apt-get update && \
    apt-get install -y trivy

# Syft
RUN curl -k -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | \
    sh -s -- -b /usr/local/bin

# Cosign
RUN wget -O /tmp/cosign.deb \
    https://github.com/sigstore/cosign/releases/download/v3.1.4/cosign_3.1.4_amd64.deb && \
    apt-get update && \
    apt-get install -y /tmp/cosign.deb && \
    rm -f /tmp/cosign.deb

USER jenkins
