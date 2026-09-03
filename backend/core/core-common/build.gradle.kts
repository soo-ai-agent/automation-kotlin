dependencies {
    // 예외가 자기 HttpStatus 를 들고 오므로 웹 타입이 필요하다. 서블릿 컨테이너는 부팅 모듈이 갖는다.
    api("org.springframework:spring-web")
}
