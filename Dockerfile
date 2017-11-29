FROM java:8
VOLUME /tmp
ADD target/spring-petclinic-1.5.1.jar app.jar
RUN bash -c 'touch /app.jar'
EXPOSE 8080
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
