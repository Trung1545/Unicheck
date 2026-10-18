package com.unicheck.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CsvImportResultResponse {

    @Builder.Default
    private int totalRecords = 0;

    @Builder.Default
    private int successCount = 0;

    @Builder.Default
    private int failedCount = 0;

    @Builder.Default
    private List<String> errors = new ArrayList<>();
}
