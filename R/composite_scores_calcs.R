# Function to calculate z-score ------------------------------------------------
calc_z <- function(x) {
  x <- as.numeric(x)
  
  valid <- is.finite(x)
  
  if (sum(valid) < 2L) {
    return(rep(NA_real_, length(x)))
  }
  
  x_mean <- mean(x[valid])
  x_sd   <- sd(x[valid])
  
  if (!is.finite(x_sd) || x_sd == 0) {
    return(rep(NA_real_, length(x)))
  }
  
  out <- rep(NA_real_, length(x))
  out[valid] <- (x[valid] - x_mean) / x_sd
  out
}

# Function to calculate domain scores ------------------------------------------
calc_domain_composite_scores <- function(
    data,
    indicator_id_col = "indicator_id",
    polarity_col = "indicator_polarity",
    domain_col = "domain",
    geography_code_col = "gp_code",
    value_col = "indicator_value",
    exclude_indicators = integer(),
    minimum_indicators = 2L,
    minimum_completeness = 0.75
) {
  
  # Validate input -------------------------------------------------------------
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  
  column_arguments <- c(
    indicator_id_col,
    polarity_col,
    domain_col,
    geography_code_col,
    value_col
  )
  
  argument_lengths <- lengths(
    list(
      indicator_id_col,
      polarity_col,
      domain_col,
      geography_code_col,
      value_col
    )
  )
  
  if (
    any(argument_lengths != 1L) ||
    any(is.na(column_arguments)) ||
    any(column_arguments == "")
  ) {
    stop(
      "All column arguments must be single, non-missing column names.",
      call. = FALSE
    )
  }
  
  required_columns <- unique(column_arguments)
  missing_columns <- setdiff(required_columns, names(data))
  
  if (length(missing_columns) > 0L) {
    stop(
      "Missing required columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }
  
  if (
    !is.numeric(minimum_indicators) ||
    length(minimum_indicators) != 1L ||
    is.na(minimum_indicators) ||
    minimum_indicators < 1 ||
    minimum_indicators %% 1 != 0
  ) {
    stop(
      "`minimum_indicators` must be a single positive integer.",
      call. = FALSE
    )
  }
  
  if (
    !is.numeric(minimum_completeness) ||
    length(minimum_completeness) != 1L ||
    is.na(minimum_completeness) ||
    minimum_completeness < 0 ||
    minimum_completeness > 1
  ) {
    stop(
      "`minimum_completeness` must be between 0 and 1.",
      call. = FALSE
    )
  }
  
  # Check indicator polarity --------------------------------------------------
  invalid_polarity <- data |>
    filter(
      !is.na(.data[[value_col]]),
      is.na(.data[[polarity_col]]) |
        !.data[[polarity_col]] %in% c(-1, 0, 1)
    ) |>
    distinct(
      indicator_id = .data[[indicator_id_col]],
      polarity = .data[[polarity_col]]
    )
  
  if (nrow(invalid_polarity) > 0L) {
    stop(
      "Some indicators with non-missing values have missing or invalid ",
      "polarity values. Expected -1, 0 or 1.",
      call. = FALSE
    )
  }
  
  # Determine expected score-contributing indicators within each domain -------
  expected_indicators <- data |>
    filter(
      !.data[[indicator_id_col]] %in% exclude_indicators,
      .data[[polarity_col]] %in% c(-1, 1)
    ) |>
    distinct(
      domain = .data[[domain_col]],
      indicator_id = .data[[indicator_id_col]]
    ) |>
    count(
      domain,
      name = "indicators_expected"
    )
  
  if (nrow(expected_indicators) == 0L) {
    stop(
      "No score-contributing indicators remain after exclusions ",
      "and polarity filtering.",
      call. = FALSE
    )
  }
  
  # Calculate domain composite scores -----------------------------------------
  result <- data |>
    filter(
      !.data[[indicator_id_col]] %in% exclude_indicators,
      .data[[polarity_col]] %in% c(-1, 1)
    ) |>
    
    # Align polarity so higher values always indicate greater concern
    mutate(
      risk_value = case_when(
        .data[[polarity_col]] == 1 ~
          -as.numeric(.data[[value_col]]),
        
        .data[[polarity_col]] == -1 ~
          as.numeric(.data[[value_col]]),
        
        TRUE ~ NA_real_
      )
    ) |>
    
    # Compare practices on each individual indicator
    group_by(
      indicator_id = .data[[indicator_id_col]]
    ) |>
    mutate(
      indicator_z = calc_z(risk_value)
    ) |>
    ungroup() |>
    
    # Combine indicators into one score per geography and domain
    group_by(
      geography_code = .data[[geography_code_col]],
      domain = .data[[domain_col]]
    ) |>
    summarise(
      indicators_used = sum(!is.na(indicator_z)),
      
      domain_mean_z = if_else(
        indicators_used > 0L,
        mean(indicator_z, na.rm = TRUE),
        NA_real_
      ),
      
      .groups = "drop"
    ) |>
    
    left_join(
      expected_indicators,
      by = "domain"
    ) |>
    
    # Apply completeness rules
    mutate(
      completeness = indicators_used / indicators_expected,
      
      score_eligible =
        indicators_used >= minimum_indicators &
        completeness >= minimum_completeness,
      
      domain_composite_score = if_else(
        score_eligible,
        domain_mean_z,
        NA_real_
      )
    ) |>
    
    # Re-standardise eligible composite scores within each domain
    group_by(domain) |>
    mutate(
      domain_standardised_score =
        calc_z(domain_composite_score),
      
      # 100 = greatest relative concern
      concern_percentile = if_else(
        is.na(domain_standardised_score),
        NA_real_,
        100 * percent_rank(domain_standardised_score)
      ),
      
      # 10 = greatest relative concern
      concern_decile = if_else(
        is.na(domain_standardised_score),
        NA_integer_,
        ntile(domain_standardised_score, 10L)
      )
    ) |>
    ungroup()
  
  result
}