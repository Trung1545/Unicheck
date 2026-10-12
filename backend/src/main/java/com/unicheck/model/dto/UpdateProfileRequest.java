package com.unicheck.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateProfileRequest {

    private String fullName;
    private String phone;
    private LocalDate dob;
    private String sex;
    private String avatar;
}
