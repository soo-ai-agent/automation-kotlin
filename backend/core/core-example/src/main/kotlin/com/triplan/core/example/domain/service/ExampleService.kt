package com.triplan.core.example.domain.service

import com.triplan.core.example.domain.model.ExampleData
import com.triplan.core.example.domain.model.ExampleResult
import org.springframework.stereotype.Service

@Service
class ExampleService {
    fun processExample(exampleData: ExampleData): ExampleResult {
        return ExampleResult(exampleData.value)
    }
}
