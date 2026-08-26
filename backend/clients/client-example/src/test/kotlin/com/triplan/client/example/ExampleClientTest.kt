package com.triplan.client.example

import com.triplan.client.ClientExampleContextTest
import feign.RetryableException
import org.assertj.core.api.Assertions
import org.junit.jupiter.api.Test

class ExampleClientTest(
    val exampleClient: ExampleClient,
) : ClientExampleContextTest() {
    @Test
    fun shouldBeThrownExceptionWhenExample() {
        try {
            exampleClient.example("HELLO!")
        } catch (e: Exception) {
            Assertions.assertThat(e).isExactlyInstanceOf(RetryableException::class.java)
        }
    }
}
