FROM tomcat:10.1-jdk17

RUN rm -rf /usr/local/tomcat/webapps/*
COPY target/*.war /usr/local/tomcat/webapps/app.war

RUN sed -i 's/Connector port="8080"/Connector port="8090"/' /usr/local/tomcat/conf/server.xml
EXPOSE 8090

CMD ["catalina.sh", "run"]
