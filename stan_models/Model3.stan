data {
  int<lower=1> N;
  int<lower=1> R_runner;
  int<lower=1> C_country;
  int<lower=1> J_year;

  vector[N] y;

  vector[N] age;
  vector[N] age2;
  vector[N] sex;

  array[N] int<lower=1, upper=R_runner> runner;
  array[N] int<lower=1, upper=C_country> country;
  array[N] int<lower=1, upper=J_year> year;

  vector[J_year] year_temp;
  vector[J_year] year_dew;
  vector[J_year] year_prec;
  vector[J_year] year_wind;

  // Prediction data

  int<lower=1, upper=R_runner> pred_runner_id;
  int<lower=1, upper=C_country> pred_country_id;

  real pred_age;
  real pred_sex;

  real pred_temp;
  real pred_dew;
  real pred_prec;
  real pred_wind;
}

parameters {

  // Fixed effects

  real b_0;
  real b_sex;
  real b_age;
  real b_age2;

  // Weather regression

  real g_0;
  real g_temp;
  real g_dew;
  real g_prec;
  real g_wind;

  // Non-centered random effects

  vector[R_runner] z_runner;
  vector[C_country] z_country;
  vector[J_year] z_year;

  real<lower=0> sigma_runner;
  real<lower=0> sigma_country;
  real<lower=0> sigma_year;

  real<lower=0> sigma_y;

  real<lower=1> nu;
}

transformed parameters {

  vector[R_runner] alpha_runner;
  vector[C_country] alpha_country;
  vector[J_year] gamma_year;

  vector[J_year] year_mean;

  year_mean =
      g_0
    + g_temp * year_temp
    + g_dew  * year_dew
    + g_prec * year_prec
    + g_wind * year_wind;

  alpha_runner = sigma_runner * z_runner;

  alpha_country = sigma_country * z_country;

  gamma_year = year_mean + sigma_year * z_year;
}

model {

  vector[N] mu;

  // Priors

  b_0    ~ normal(5.5, 1);
  b_sex  ~ normal(0, 1);
  b_age  ~ normal(0, 1);
  b_age2 ~ normal(0, 1);

  g_0    ~ normal(0, 5);
  g_temp ~ normal(0, 2);
  g_dew  ~ normal(0, 2);
  g_prec ~ normal(0, 2);
  g_wind ~ normal(0, 2);

  sigma_runner  ~ normal(0, 1);
  sigma_country ~ normal(0, 1);
  sigma_year    ~ normal(0, 1);

  sigma_y ~ normal(0, 1);

  nu ~ gamma(2, 0.1);

  // Non-centered priors

  z_runner  ~ normal(0, 1);
  z_country ~ normal(0, 1);
  z_year    ~ normal(0, 1);

  // Linear predictor

  for (n in 1:N) {

    mu[n] =
        b_0
      + b_sex * sex[n]
      + b_age * age[n]
      + b_age2 * age2[n]
      + alpha_runner[runner[n]]
      + alpha_country[country[n]]
      + gamma_year[year[n]];
  }

  y ~ student_t(nu, mu, sigma_y);
}

generated quantities {

  real gamma_year_new;

  real y_tilde_existing;
  real y_tilde_new_runner;

  real alpha_runner_new;

  real mu_existing;
  real mu_new;

  gamma_year_new =
      normal_rng(
          g_0
        + g_temp * pred_temp
        + g_dew * pred_dew
        + g_prec * pred_prec
        + g_wind * pred_wind,
        sigma_year
      );

  mu_existing =
      b_0
      + b_sex * pred_sex
      + b_age * pred_age
      + b_age2 * square(pred_age)
      + alpha_runner[pred_runner_id]
      + alpha_country[pred_country_id]
      + gamma_year_new;

  y_tilde_existing =
      student_t_rng(
          nu,
          mu_existing,
          sigma_y
      );

  alpha_runner_new =
      normal_rng(
          0,
          sigma_runner
      );

  mu_new =
      b_0
      + b_sex * pred_sex
      + b_age * pred_age
      + b_age2 * square(pred_age)
      + alpha_runner_new
      + alpha_country[pred_country_id]
      + gamma_year_new;

  y_tilde_new_runner =
      student_t_rng(
          nu,
          mu_new,
          sigma_y
      );
}