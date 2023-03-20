FROM eclipse-temurin:17.0.6_10-jdk
SHELL ["/bin/bash", "-c"]

ENV KOPS_STATE_STORE=${KOPS_STATE_STORE}
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

ENV M2_HOME=/opt/apache-maven-3.9.0
ENV MAVEN_OPTS="-Xms256m -Xmx512m"

RUN mkdir -p /root/jenkins/restaurant-resources
COPY k8s-components/fullstack-secrets.yaml /root/jenkins/restaurant-resources/
COPY tomcat-users.xml /root/jenkins/restaurant-resources/
COPY context.xml /root/jenkins/restaurant-resources/
COPY server.xml /root/jenkins/restaurant-resources/

RUN apt-get update

#install docker
RUN apt-get -y --no-install-recommends install ca-certificates gnupg lsb-release && \
  mkdir -m 0755 -p /etc/apt/keyrings && \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get -y --no-install-recommends install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#install awscli, maven, curl
RUN apt-get -y --no-install-recommends install awscli && \
    apt-get -y --no-install-recommends install maven && \
    apt-get -y --no-install-recommends install curl

#install kops
RUN curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64 && \
	chmod +x kops && mv kops /usr/local/bin/kops

#install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
	install -o root -m 0755 kubectl /usr/local/bin

CMD ["/bin/echo", "complete"]