FROM eclipse-temurin:17.0.6_10-jdk
SHELL ["/bin/bash", "-c"]

ENV TOMCAT_VERSION=10.1.8

RUN useradd -m -U -d /opt/tomcat -s /bin/false tomcat
RUN wget https://archive.apache.org/dist/tomcat/tomcat-10/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz && \
    tar -xf apache-tomcat-$TOMCAT_VERSION.tar.gz -C /opt/tomcat && \
    rm apache-tomcat-$TOMCAT_VERSION.tar.gz && \
    chown -R tomcat: /opt/tomcat

COPY TablesService.war /opt/tomcat/apache-tomcat-$TOMCAT_VERSION/webapps
COPY tomcat-users.xml /opt/tomcat/apache-tomcat-$TOMCAT_VERSION/conf
COPY context.xml /opt/tomcat/apache-tomcat-$TOMCAT_VERSION/webapps/manager/META-INF
COPY server.xml /opt/tomcat/apache-tomcat-$TOMCAT_VERSION/conf

HEALTHCHECK --interval=30m --timeout=3s CMD curl --fail http://localhost:80 || exit 1

CMD ["bash", "-c", "/opt/tomcat/apache-tomcat-$TOMCAT_VERSION/bin/catalina.sh run"]
