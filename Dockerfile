FROM bentolor/docker-dind-awscli:dind

ENV KOPS_STATE_STORE=${KOPS_STATE_STORE}
#ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
#ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

ENV M2_HOME=/opt/apache-maven-3.9.0
ENV MAVEN_OPTS="-Xms256m -Xmx512m"

RUN mkdir -p /root/jenkins/restaurant-resources
COPY TableService/tomcat-users.xml /root/jenkins/restaurant-resources/
COPY TableService/context.xml /root/jenkins/restaurant-resources/
COPY TableService/server.xml /root/jenkins/restaurant-resources/

RUN apk add maven curl git

#install kops
RUN curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64 && \
	chmod +x kops && mv kops /usr/local/bin/kops

#install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
	install -o root -m 0755 kubectl /usr/local/bin

RUN rm -rf /var/cache/apk/*

CMD ["/bin/echo", "complete"]