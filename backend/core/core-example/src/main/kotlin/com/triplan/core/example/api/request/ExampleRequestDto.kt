package com.triplan.core.example.api.request

import com.triplan.core.example.domain.model.ExampleData

data class ExampleRequestDto(
    val data: String,
) {
    fun toExampleData(): ExampleData {
        return ExampleData(data, data)
    }
}
