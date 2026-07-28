# Railway가 backend/ 를 루트로 감지하면 이 Dockerfile을 자동으로 사용해 빌드한다.
# 로컬 gradle wrapper가 JDK 17 툴체인을 요구하므로(build.gradle) 빌드/런타임 모두 17로 고정한다.

FROM eclipse-temurin:17-jdk AS build
WORKDIR /app
COPY gradlew settings.gradle build.gradle ./
COPY gradle gradle
RUN chmod +x gradlew && ./gradlew --version
COPY src src
RUN ./gradlew bootJar --no-daemon -x test

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
