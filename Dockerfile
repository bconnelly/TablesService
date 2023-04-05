FROM eclipse-temurin:17.0.6_10-jdk
SHELL ["/bin/bash", "-c"]

RUN useradd -m -U -d /opt/tomcat -s /bin/false tomcat
RUN wget https://downloads.apache.org/tomcat/tomcat-10/v10.1.7/bin/apache-tomcat-10.1.7.tar.gz && \
    tar -xf apache-tomcat-10.1.7.tar.gz -C /opt/tomcat && \
    rm apache-tomcat-10.1.7.tar.gz && \
    chown -R tomcat: /opt/tomcat

COPY TablesService.war /opt/tomcat/apache-tomcat-10.1.7/webapps
COPY tomcat-users.xml /opt/tomcat/apache-tomcat-10.1.7/conf
COPY context.xml /opt/tomcat/apache-tomcat-10.1.7/webapps/manager/META-INF
COPY server.xml /opt/tomcat/apache-tomcat-10.1.7/conf

RUN echo "0" > healthy

CMD ["/opt/tomcat/apache-tomcat-10.1.7/bin/catalina.sh", "run"]