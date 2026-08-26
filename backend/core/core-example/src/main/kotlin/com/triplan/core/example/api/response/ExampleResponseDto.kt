package com.triplan.core.example.api.response

import java.time.LocalDate
import java.time.LocalDateTime

data class ExampleResponseDto(
    val result: String,
    val date: LocalDate,
    val datetime: LocalDateTime,
    val items: List<ExampleItemResponseDto>,
)
