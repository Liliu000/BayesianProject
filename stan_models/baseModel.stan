data {
  int<lower=0> N;
  vector[N] log_time;
  vector[N] sex;
  vector[N] age;
  vector[N] age2;
}

parameters {
  real beta0;                  
  real beta_sex;               
  real beta_age;               
  real beta_age2;              
  real<lower=0> sigma;         // Stan applies Uniform(0, infinity)
  real<lower=1> nu;            // Stan applies Uniform(1, infinity)
}

transformed parameters {
  vector[N] mu;
  mu = beta0 + beta_sex * sex + beta_age * age + beta_age2 * age2;
}

model {
  // NO PRIORS SPECIFIED 
  // This defaults to Uniform/Flat priors for all parameters
  
  // Diffuse priors: they allow almost any value but help the math stay stable
  beta0 ~ normal(0, 100);
  beta_sex ~ normal(0, 100);
  beta_age ~ normal(0, 100);
  beta_age2 ~ normal(0, 100);
  sigma ~ cauchy(0, 25); 
  nu ~ exponential(0.01); // Very flat distribution for Nu
  // Likelihood
  log_time ~ student_t(nu, mu, sigma);
}