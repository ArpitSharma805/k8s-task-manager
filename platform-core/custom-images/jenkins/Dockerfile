FROM jenkins/jenkins:2.580.2-jdk25

USER root

COPY DellRoot2018.cer /tmp/DellRoot2018.cer

RUN keytool -importcert \
    -alias dellroot2018 \
    -file /tmp/DellRoot2018.cer \
    -keystore /opt/java/openjdk/lib/security/cacerts \
    -storepass changeit \
    -noprompt

USER jenkins
