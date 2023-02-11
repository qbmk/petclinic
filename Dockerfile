FROM eclipse-temurin:17-jdk-jammy

ARG JAR_FILE=target/*.jar

ENV MYSQL_URL=jdbc:mysql://10.53.39.3/petclinic

WORKDIR /opt/petclinic

COPY ${JAR_FILE} petclinic.jar

ENTRYPOINT ["java", "-jar", "-Dspring.profiles.active=mysql", "/opt/petclinic/petclinic.jar"]

EXPOSE 8080