package com.triplan.core.example.api.response

data class ExampleItemResponseDto(
    val key: String,
) {
    companion object {
        fun build(): List<ExampleItemResponseDto> {
            return listOf(ExampleItemResponseDto("1"), ExampleItemResponseDto("2"))
        }
    }
}
