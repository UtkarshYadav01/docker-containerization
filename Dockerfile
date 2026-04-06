FROM amazoncorretto:26-jdk
LABEL authors="Utkarsh"
ADD target/rest-demo.jar rest-demo.jar
ENTRYPOINT ["java","-jar","/rest-demo.jar"]