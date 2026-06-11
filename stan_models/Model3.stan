data {
  int<lower=0> N;                // Number of observations
  int<lower=0> R_runner;         // Number of unique runners
  int<lower=0> C_country;        // Number of countries
  int<lower=0> J_year;           // Number of years (6)
  
  vector[N] y;                   // Log Time
  vector[N] age;                 // Standardized Age
  vector[N] age2;                // Age squared
  vector[N] sex;                 // 0 or 1
  
  int runner[N];                 // Runner ID index
  int country[N];                // Country ID index
  int year[N];                   // Year ID index
  
  vector[J_year] year_temp;      // Temperature per year (multilevel covariate)
  
    // Data for prediction
  int pred_runner_id;      // Index of a specific runner to predict
  int pred_country_id;     // Index of their country
  real pred_age;           // Their age
  real pred_sex;           // Their sex
  real pred_temp;          // Temperature of the year we want to predict
}

parameters {
  // Population level effects (Fixed effects)
  real b_0;
  real b_sex;
  real b_age;
  real b_age2;
  
  // Group level effects (Random intercepts)
  vector[R_runner] alpha_runner;
  vector[C_country] alpha_country;
  vector[J_year] gamma_year;
  
  // Parameters for the Year-level covariate (like g_0, g_1 in radon)
  real g_0; 
  real g_temp;
  
  // Hyper-parameters (Variances)
  real<lower=0> sigma_y;
  real<lower=0> sigma_runner;
  real<lower=0> sigma_country;
  real<lower=0> sigma_year;
  
  // Degrees of freedom for Student-t
  real<lower=1> nu;
}

model {
  // 1. Priors for Year Intercept (The Multilevel Covariate part)
  // This explains year-to-year variation using temperature
  gamma_year ~ normal(g_0 + g_temp * year_temp, sigma_year);
  
  // 2. Priors for other levels
  alpha_runner ~ normal(0, sigma_runner);
  alpha_country ~ normal(0, sigma_country);
  
  // 3. Fixed effects priors
  // b_0 ~ normal(5, 2);
  // b_sex ~ normal(0, 1);
  // b_age ~ normal(0, 1);
  // b_age2 ~ normal(0, 1);
  // sigma_y ~ cauchy(0, 25); 
  // nu ~ gamma(2, 0.1); 
  nu ~ exponential(0.01);

  // 4. Likelihood
  for (n in 1:N) {
    real mu = b_0 + 
              b_sex * sex[n] + 
              b_age * age[n] + 
              b_age2 * age2[n] + 
              alpha_runner[runner[n]] + 
              alpha_country[country[n]] + 
              gamma_year[year[n]];
              
    y[n] ~ student_t(nu, mu, sigma_y);
  }
}


generated quantities {
  real y_tilde_existing;
  real y_tilde_new_runner;
  
  // 1. Predict for an EXISTING runner in a NEW year (given a temperature)
  // We simulate a new year effect first
  real gamma_year_new = normal_rng(g_0 + g_temp * pred_temp, sigma_year);
  
  real mu_ex = b_0 + b_sex * pred_sex + b_age * pred_age + b_age2 * (pred_age^2) + 
               alpha_runner[pred_runner_id] + alpha_country[pred_country_id] + gamma_year_new;
  
  y_tilde_existing = student_t_rng(nu, mu_ex, sigma_y);
  
  // 2. Predict for a NEW runner (randomly drawn from the population)
  real alpha_runner_new = normal_rng(0, sigma_runner);
  
  real mu_new = b_0 + b_sex * pred_sex + b_age * pred_age + b_age2 * (pred_age^2) + 
                alpha_runner_new + alpha_country[pred_country_id] + gamma_year_new;
                
  y_tilde_new_runner = student_t_rng(nu, mu_new, sigma_y);
}