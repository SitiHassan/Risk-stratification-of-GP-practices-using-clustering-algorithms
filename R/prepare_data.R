library(tidyverse)
library(readxl)

# Get data 
data <- read_xlsx("data/data.xlsx")

data |>
  filter(indicator_level == 'GP Level',
         indicator_polarity %in% c(-1, 1),
         indicator_id != 7) |>
  distinct(indicator_id, domain, indicator_polarity) |>
  arrange(indicator_id)

gp_domain_composite_score <- calc_domain_composite_scores(
  data = data |> filter(indicator_level == "GP Level"),
  indicator_id_col = "indicator_id",
  polarity_col = "indicator_polarity",
  domain_col = "domain",
  geography_code_col = "geography_code",
  value_col = "indicator_value",
  exclude_indicators = 7,
  minimum_indicators = 1L,
  minimum_completeness = 0.75
)

head(gp_domain_composite_score)

# GP cluster data --------------------------------------------------------------
gp_cluster_data <- gp_domain_composite_score |>
  select(
    geography_code,
    domain,
    domain_standardised_score
  ) |>
  pivot_wider(
    names_from = domain,
    values_from = domain_standardised_score
  )

