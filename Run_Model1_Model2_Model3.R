library(readr)
library(dplyr)
library(lubridate)

df <- read_csv("data/repeated_ids_with_countries.csv")

df_model <- df %>%
  mutate(
    log_time = log(as.numeric(hms(`Official Time`)) / 3600),
    Sex = ifelse(`M/F` == "M", 1, 0),
    Age = as.numeric(scale(Age)),
    Age2 = Age^2,
    year_id = as.integer(as.factor(Year)),
    country_id = as.integer(as.factor(Country)),
    runner_id = as.integer(as.factor(ID))
  ) %>%
  filter(!is.na(log_time)) %>%
  mutate(Year = as.integer(Year))


# Model 1
stan_data_model1 <- list(
  N = nrow(df_model),
  log_time = df_model$log_time,
  Sex = df_model$Sex,
  Age = df_model$Age,
  Age2 = df_model$Age2,
  C_year = length(unique(df_model$year_id)),
  year_id = df_model$year_id
)

# Model 2
stan_data_model2 <- list(
  N = nrow(df_model),
  log_time = df_model$log_time,
  Sex = df_model$Sex,
  Age = df_model$Age,
  Age2 = df_model$Age2,
  C_year = length(unique(df_model$year_id)),
  year_id = df_model$year_id,
  C_country = length(unique(df_model$country_id)),
  country_id = df_model$country_id
)

# Model 3
stan_data_model3 <- list(
  N = nrow(df_model),
  log_time = df_model$log_time,
  Sex = df_model$Sex,
  Age = df_model$Age,
  Age2 = df_model$Age2,
  C_year = length(unique(df_model$year_id)),
  year_id = df_model$year_id,
  C_country = length(unique(df_model$country_id)),
  country_id = df_model$country_id,
  C_runner = length(unique(df_model$runner_id)),
  runner_id = df_model$runner_id
)


# Model well aligned:
glimpse(df_model)
summary(df_model)

df_model %>% count(Year)
df_model %>% count(`M/F`)
df_model %>% summarise(
  n = n(),
  runners = n_distinct(ID),
  countries = n_distinct(Country),
  years = n_distinct(Year)
)

df_model %>%
  summarise(
    min_age = min(Age),
    max_age = max(Age),
    min_time = min(log_time),
    max_time = max(log_time)
  )


# ============================================================
# MODEL 1 - RESULTS AND DIAGNOSTICS
# ============================================================
library(dplyr)
library(bayesplot)
#install.packages("cmdstanr",repos = c("https://stan-dev.r-universe.dev","https://cloud.r-project.org"))
#install_cmdstan()
library(cmdstanr)

mod1 <- cmdstan_model("stan_models/Model1.stan")

fit1 <- mod1$sample(
  data = stan_data_model1,
  seed = 123,
  chains = 4,
  parallel_chains = 4,
  iter_warmup = 1000,
  iter_sampling = 1000,
  adapt_delta = 0.95,
  max_treedepth = 15
)


# ------------------------------------------------------------
# Main parameters
# ------------------------------------------------------------

fit1$summary(c(
  "beta0",
  "beta_sex",
  "beta_age",
  "beta_age2",
  "sigma",
  "sigma_year"
))

# Interpretation:
# beta_sex   -> effect of gender on marathon performance
# beta_age   -> linear age effect
# beta_age2  -> quadratic age effect
# sigma      -> residual variability not explained by the model
# sigma_year -> variability between marathon editions



# ------------------------------------------------------------
# Convergence diagnostics
# ------------------------------------------------------------

fit1$summary(c(
  "beta0",
  "beta_sex",
  "beta_age",
  "beta_age2",
  "sigma",
  "sigma_year"
)) %>%
  select(variable, rhat, ess_bulk, ess_tail)

# Interpretation:
# Rhat values close to 1 indicate good convergence.
# ESS (Effective Sample Size) should be sufficiently large.
# Values above a few hundred are generally considered adequate.


# ------------------------------------------------------------
# Year effects
# ------------------------------------------------------------

fit1$summary(c(
  "alpha_year[1]",
  "alpha_year[2]",
  "alpha_year[3]",
  "alpha_year[4]",
  "alpha_year[5]",
  "alpha_year[6]"
))

# Interpretation:
# Negative effects correspond to faster-than-average years.
# Positive effects correspond to slower-than-average years.


# ------------------------------------------------------------
# Map year IDs to actual marathon years
# ------------------------------------------------------------

year_map <- df_model %>%
  distinct(year_id, Year) %>%
  arrange(year_id)

year_effects_named <- fit1$summary(
  paste0("alpha_year[", 1:6, "]")
) %>%
  mutate(
    year_id = as.integer(
      gsub("alpha_year\\[|\\]", "", variable)
    )
  ) %>%
  left_join(year_map, by = "year_id") %>%
  select(Year, mean, q5, q95) %>%
  arrange(Year)

year_effects_named

# This table reports the estimated effect of each marathon year
# after controlling for age and gender.


# ------------------------------------------------------------
# Fastest years
# ------------------------------------------------------------

year_effects_named %>%
  arrange(mean)

# Years with the most negative effects correspond to the
# fastest marathon editions in the dataset.


# ------------------------------------------------------------
# Slowest years
# ------------------------------------------------------------

year_effects_named %>%
  arrange(desc(mean))

# Years with the most positive effects correspond to the
# slowest marathon editions in the dataset.


# ------------------------------------------------------------
# Posterior distributions
# ------------------------------------------------------------

mcmc_dens(
  fit1$draws(c(
    "beta_sex",
    "beta_age",
    "beta_age2",
    "sigma_year"
  ))
)

# Interpretation:
# These plots show the posterior uncertainty of the
# main model parameters.


# ------------------------------------------------------------
# Trace plots
# ------------------------------------------------------------

mcmc_trace(
  fit1$draws(c(
    "beta_sex",
    "beta_age",
    "sigma_year"
  ))
)

# Interpretation:
# Chains should mix well and overlap without visible trends.
# Good mixing indicates satisfactory convergence.


# ------------------------------------------------------------
# Year-level variability
# ------------------------------------------------------------

fit1$summary("sigma_year")

# Interpretation:
#
# sigma_year measures the variability between marathon editions.
#
# A value close to zero would indicate that race year has
# little influence on performance.
#
# Larger values suggest meaningful differences between years,
# potentially reflecting weather conditions, race organization,
# or other unobserved factors.


# ------------------------------------------------------------
# Save model
# ------------------------------------------------------------

saveRDS(fit1, "fit_model1.rds")




# ============================================================
# MODEL 2 
# ============================================================
## Model 2 = Model 1 + hierarchical country.
mod2 <- cmdstan_model("stan_models/Model2.stan")

fit2 <- mod2$sample(
  data = stan_data_model2,
  seed = 123,
  chains = 4,
  parallel_chains = 4,
  iter_warmup = 1000,
  iter_sampling = 1000,
  adapt_delta = 0.95,
  max_treedepth = 15
)

# Interpretation:
# beta_sex      -> effect of gender on marathon time
# beta_age      -> linear age effect
# beta_age2     -> quadratic age effect
# sigma         -> residual variability
# sigma_year    -> variability between race years
# sigma_country -> variability between countries

# Report:
# All parameters should ideally have Rhat close to 1.00
# and sufficiently large effective sample sizes (ESS).


# ------------------------------------------------------------
# Year effects
# ------------------------------------------------------------

fit2$summary(c(
  "alpha_year[1]",
  "alpha_year[2]",
  "alpha_year[3]",
  "alpha_year[4]",
  "alpha_year[5]",
  "alpha_year[6]"
))

# Interpretation:
# Negative values indicate faster-than-average years.
# Positive values indicate slower-than-average years.


# ------------------------------------------------------------
# Country effects
# ------------------------------------------------------------

country_effects <- fit2$summary("alpha_country") %>%
  select(variable, mean, q5, q95)

# Map country_id back to country names

country_map <- df_model %>%
  distinct(country_id, Country) %>%
  arrange(country_id)

country_effects_named <- fit2$summary("alpha_country") %>%
  mutate(
    country_id = as.integer(
      gsub("alpha_country\\[|\\]", "", variable)
    )
  ) %>%
  left_join(country_map, by = "country_id") %>%
  select(Country, mean, q5, q95) %>%
  arrange(mean)

country_effects_named

# Interpretation:
# Negative country effects correspond to countries
# whose runners tend to be faster than average,
# after controlling for age, sex and year.
#
# Positive values indicate slower average performance.


# ------------------------------------------------------------
# Top 10 fastest countries
# ------------------------------------------------------------

country_effects_named %>%
  head(10)

# These countries have the lowest estimated finish times.


# ------------------------------------------------------------
# Top 10 slowest countries
# ------------------------------------------------------------

country_effects_named %>%
  arrange(desc(mean)) %>%
  head(10)

# These countries have the highest estimated finish times.


# ------------------------------------------------------------
# Posterior distributions
# ------------------------------------------------------------

mcmc_dens(
  fit2$draws(c(
    "beta_sex",
    "beta_age",
    "beta_age2",
    "sigma_year",
    "sigma_country"
  ))
)

# Interpretation:
# Visualizes posterior uncertainty of the main parameters.


# ------------------------------------------------------------
# Trace plots
# ------------------------------------------------------------
library(dplyr)
library(bayesplot)
mcmc_trace(
  fit2$draws(c(
    "beta_sex",
    "beta_age",
    "sigma_year",
    "sigma_country"
  ))
)

# Interpretation:
# Good convergence is indicated by chains mixing well
# and showing no visible trends.


# ------------------------------------------------------------
# Variability comparison
# ------------------------------------------------------------

fit2$summary(c(
  "sigma_year",
  "sigma_country"
))

# Interpretation:
#
# If sigma_country << sigma_year:
# Country-level variability is small compared to
# differences between race editions.
#
# If sigma_country ≈ sigma_year:
# Country effects explain a substantial part of
# marathon performance variability.
#
# If sigma_country > sigma_year:
# Country differences are more important than
# year-to-year differences.


# ------------------------------------------------------------
# Save results
# ------------------------------------------------------------

saveRDS(fit2, "fit_model2.rds")




# ============================================================
# MODEL 3
# ============================================================
# Model 3 = Model 2 + hierarchical runner effect.
# This model accounts for repeated runners across different years.

library(cmdstanr)
library(dplyr)
library(bayesplot)

# ------------------------------------------------------------
# Compile and run Model 3
# ------------------------------------------------------------

mod3 <- cmdstan_model("stan_models/Model3_simple.stan")

fit3 <- mod3$sample(
  data = stan_data_model3,
  seed = 123,
  chains = 4,
  parallel_chains = 4,
  iter_warmup = 1000,
  iter_sampling = 1000,
  adapt_delta = 0.95,
  max_treedepth = 15
)

 # ------------------------------------------------------------
# Main parameters
# ------------------------------------------------------------

fit3$summary(c(
  "beta0",
  "beta_sex",
  "beta_age",
  "beta_age2",
  "sigma",
  "sigma_year",
  "sigma_country",
  "sigma_runner"
))

# Interpretation:
# beta_sex       -> effect of gender on marathon time
# beta_age       -> linear age effect
# beta_age2      -> quadratic age effect
# sigma          -> residual variability
# sigma_year     -> variability between race years
# sigma_country  -> variability between countries
# sigma_runner   -> variability between individual runners


# ------------------------------------------------------------
# Convergence diagnostics
# ------------------------------------------------------------

fit3$summary(c(
  "beta0",
  "beta_sex",
  "beta_age",
  "beta_age2",
  "sigma",
  "sigma_year",
  "sigma_country",
  "sigma_runner"
)) %>%
  select(variable, rhat, ess_bulk, ess_tail)

# Interpretation:
# Rhat should be close to 1.00.
# ESS should be sufficiently large.


# ------------------------------------------------------------
# Year effects
# ------------------------------------------------------------

year_map <- df_model %>%
  distinct(year_id, Year) %>%
  arrange(year_id)

year_effects_named_3 <- fit3$summary("alpha_year") %>%
  mutate(
    year_id = as.integer(gsub("alpha_year\\[|\\]", "", variable))
  ) %>%
  left_join(year_map, by = "year_id") %>%
  select(Year, mean, q5, q95) %>%
  arrange(Year)

year_effects_named_3

# Negative values indicate faster-than-average years.
# Positive values indicate slower-than-average years.


# ------------------------------------------------------------
# Country effects
# ------------------------------------------------------------

country_map <- df_model %>%
  distinct(country_id, Country) %>%
  arrange(country_id)

country_effects_named_3 <- fit3$summary("alpha_country") %>%
  mutate(
    country_id = as.integer(gsub("alpha_country\\[|\\]", "", variable))
  ) %>%
  left_join(country_map, by = "country_id") %>%
  select(Country, mean, q5, q95) %>%
  arrange(mean)

country_effects_named_3

# Negative country effects correspond to faster-than-average countries,
# after controlling for age, sex, year and runner-level effects.


# ------------------------------------------------------------
# Top 10 fastest countries
# ------------------------------------------------------------

country_effects_named_3 %>%
  head(10)


# ------------------------------------------------------------
# Top 10 slowest countries
# ------------------------------------------------------------

country_effects_named_3 %>%
  arrange(desc(mean)) %>%
  head(10)


# ------------------------------------------------------------
# Runner effects
# ------------------------------------------------------------

runner_map <- df_model %>%
  distinct(runner_id, ID, Name) %>%
  arrange(runner_id)

runner_effects_named_3 <- fit3$summary("alpha_runner") %>%
  mutate(
    runner_id = as.integer(gsub("alpha_runner\\[|\\]", "", variable))
  ) %>%
  left_join(runner_map, by = "runner_id") %>%
  select(ID, Name, mean, q5, q95) %>%
  arrange(mean)

runner_effects_named_3

# Negative runner effects indicate runners who are consistently faster
# than expected given their age, sex, country and race year.


# ------------------------------------------------------------
# Top 10 fastest repeated runners
# ------------------------------------------------------------

runner_effects_named_3 %>%
  head(10)


# ------------------------------------------------------------
# Top 10 slowest repeated runners
# ------------------------------------------------------------

runner_effects_named_3 %>%
  arrange(desc(mean)) %>%
  head(10)


# ------------------------------------------------------------
# Posterior distributions
# ------------------------------------------------------------

mcmc_dens(
  fit3$draws(c(
    "beta_sex",
    "beta_age",
    "beta_age2",
    "sigma_year",
    "sigma_country",
    "sigma_runner"
  ))
)

# Visualizes posterior uncertainty of the main parameters.


# ------------------------------------------------------------
# Trace plots
# ------------------------------------------------------------

mcmc_trace(
  fit3$draws(c(
    "beta_sex",
    "beta_age",
    "sigma_year",
    "sigma_country",
    "sigma_runner"
  ))
)

# Good convergence is indicated by chains mixing well
# and showing no visible trends.


# ------------------------------------------------------------
# Variability comparison
# ------------------------------------------------------------

fit3$summary(c(
  "sigma_year",
  "sigma_country",
  "sigma_runner"
))

# Interpretation:
#
# sigma_year measures variability between race editions.
# sigma_country measures variability between countries.
# sigma_runner measures variability between individual runners.
#
# If sigma_runner is the largest, individual runner heterogeneity
# is the main source of unexplained performance variability.


# ------------------------------------------------------------
# Save results
# ------------------------------------------------------------

saveRDS(fit3, "fit_model3.rds")

# ------------------------------------------------------------

# Diagnose:
fit1$cmdstan_diagnose()
fit2$cmdstan_diagnose()


# MODEL COMPARISON:
model_comparison <- tibble::tibble(
  Model = c("Model 1", "Model 2", "Model 3"),
  Description = c(
    "Age + Sex + Year",
    "Age + Sex + Year + Country",
    "Age + Sex + Year + Country + Runner"
  ),
  sigma = c(0.0915, 0.0915, 0.0400),
  sigma_year = c(0.0241, 0.0248, 0.0232),
  sigma_country = c(NA, 0.110, 0.0938),
  sigma_runner = c(NA, NA, 0.129)
)

model_comparison

save(
  fit1,
  fit2,
  fit3,
  file = "BostonMarathonFits.RData"
)
