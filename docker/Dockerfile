FROM openjdk:jdk-buster

RUN apt-get update
RUN apt-get install wget procps ldap-utils -y

WORKDIR /tmp

RUN wget https://apache.mirrors.benatherton.com//directory/apacheds/dist/2.0.0.AM26/apacheds-2.0.0.AM26-amd64.deb

RUN chmod +x apacheds-2.0.0.AM26-amd64.deb

RUN dpkg -i apacheds-2.0.0.AM26-amd64.deb

EXPOSE 10389 10636

ADD apacheds.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/apacheds.sh

ENTRYPOINT /usr/local/bin/apacheds.sh
