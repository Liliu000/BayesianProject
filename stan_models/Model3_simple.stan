data {
  int<lower=1> N;
  vector[N] log_time;
  vector[N] Sex;
  vector[N] Age;
  vector[N] Age2;

  int<lower=1> C_year;
  array[N] int<lower=1, upper=C_year> year_id;

  int<lower=1> C_country;
  array[N] int<lower=1, upper=C_country> country_id;

  int<lower=1> C_runner;
  array[N] int<lower=1, upper=C_runner> runner_id;
}

parameters {
  real beta0;
  real beta_sex;
  real beta_age;
  real beta_age2;

  vector[C_year] z_year;
  vector[C_country] z_country;
  vector[C_runner] z_runner;

  real<lower=0> sigma_year;
  real<lower=0> sigma_country;
  real<lower=0> sigma_runner;
  real<lower=0> sigma;

  real<lower=1> nu;
}

transformed parameters {
  vector[C_year] alpha_year;
  vector[C_country] alpha_country;
  vector[C_runner] alpha_runner;

  alpha_year = sigma_year * z_year;
  alpha_country = sigma_country * z_country;
  alpha_runner = sigma_runner * z_runner;
}

model {
  vector[N] mu;

  beta0 ~ normal(1.3, 0.5);
  beta_sex ~ normal(0, 1);
  beta_age ~ normal(0, 1);
  beta_age2 ~ normal(0, 1);

  sigma_year ~ normal(0, 1);
  sigma_country ~ normal(0, 1);
  sigma_runner ~ normal(0, 1);
  sigma ~ normal(0, 1);

  nu ~ gamma(2, 0.1);

  z_year ~ normal(0, 1);
  z_country ~ normal(0, 1);
  z_runner ~ normal(0, 1);

  for (n in 1:N) {
    mu[n] =
      beta0
      + beta_sex * Sex[n]
      + beta_age * Age[n]
      + beta_age2 * Age2[n]
      + alpha_year[year_id[n]]
      + alpha_country[country_id[n]]
      + alpha_runner[runner_id[n]];
  }

  log_time ~ student_t(nu, mu, sigma);
}