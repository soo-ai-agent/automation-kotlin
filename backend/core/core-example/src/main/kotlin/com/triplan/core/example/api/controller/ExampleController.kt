package com.triplan.core.example.api.controller

import com.triplan.core.common.response.ApiResponse
import com.triplan.core.example.api.request.ExampleRequestDto
import com.triplan.core.example.api.response.ExampleItemResponseDto
import com.triplan.core.example.api.response.ExampleResponseDto
import com.triplan.core.example.domain.model.ExampleData
import com.triplan.core.example.domain.service.ExampleService
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.time.LocalDate
import java.time.LocalDateTime

@RestController
class ExampleController(
    private val exampleService: ExampleService,
) {
    @GetMapping("/get/{exampleValue}")
    fun exampleGet(
        @PathVariable exampleValue: String,
        @RequestParam exampleParam: String,
    ): ApiResponse<ExampleResponseDto> {
        val result = exampleService.processExample(ExampleData(exampleValue, exampleParam))
        return ApiResponse.success(ExampleResponseDto(result.data, LocalDate.now(), LocalDateTime.now(), ExampleItemResponseDto.build()))
    }

    @PostMapping("/post")
    fun examplePost(
        @RequestBody request: ExampleRequestDto,
    ): ApiResponse<ExampleResponseDto> {
        val result = exampleService.processExample(request.toExampleData())
        return ApiResponse.success(ExampleResponseDto(result.data, LocalDate.now(), LocalDateTime.now(), ExampleItemResponseDto.build()))
    }
}
