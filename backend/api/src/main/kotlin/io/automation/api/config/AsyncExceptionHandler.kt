package io.automation.api.config

import io.automation.core.common.error.ApiException
import org.slf4j.LoggerFactory
import org.springframework.aop.interceptor.AsyncUncaughtExceptionHandler
import java.lang.reflect.Method

class AsyncExceptionHandler : AsyncUncaughtExceptionHandler {
    private val log = LoggerFactory.getLogger(javaClass)

    override fun handleUncaughtException(e: Throwable, method: Method, vararg params: Any?) {
        if (e is ApiException && !e.status.is5xxServerError) {
            log.warn("{} : {}", e.code, e.message)
        } else {
            log.error("Exception : {}", e.message, e)
        }
    }
}
