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
}

parameters {
  real beta0;
  real beta_sex;
  real beta_age;
  real beta_age2;

  vector[C_year] alpha_year;
  real<lower=0> sigma_year;

  vector[C_country] alpha_country;
  real<lower=0> sigma_country;

  real<lower=0> sigma;
  real<lower=2> nu;
}

model {
  beta0 ~ normal(0, 10);
  beta_sex ~ normal(0, 5);
  beta_age ~ normal(0, 5);
  beta_age2 ~ normal(0, 5);

  sigma ~ normal(0, 2);
  sigma_year ~ normal(0, 2);
  sigma_country ~ normal(0, 2);
  nu ~ gamma(2, 0.1);

  alpha_year ~ normal(0, sigma_year);
  alpha_country ~ normal(0, sigma_country);

  log_time ~ student_t(
    nu,
    beta0 + beta_sex * Sex + beta_age * Age + beta_age2 * Age2 +
      alpha_year[year_id] + alpha_country[country_id],
    sigma
  );
}

generated quantities {
  vector[N] y_rep;

  for (i in 1:N) {
    y_rep[i] = student_t_rng(
      nu,
      beta0 + beta_sex * Sex[i] + beta_age * Age[i] + beta_age2 * Age2[i] +
        alpha_year[year_id[i]] + alpha_country[country_id[i]],
      sigma
    );
  }
}