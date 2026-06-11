This section details the statistical framework and the progression of models used to analyze the determinants of marathon performance. All models are implemented within a Bayesian framework to properly account for parameter uncertainty and the hierarchical structure of the data.

\subsection{Bayesian Framework and Distributional Choice}

The Bayesian approach allows us to treat model parameters as random variables, providing a full posterior distribution rather than just point estimates. This is particularly valuable in sports science, where variability between individuals and race conditions is high.

A critical step in the methodology was determining the appropriate likelihood for the response variable. Marathon finishing times are known to exhibit "heavy tails," with a small number of elite athletes performing significantly better than the mean, and a wide spread among recreational runners. To compare the suitability of different distributions, a Generalized Additive Model for Location, Scale and Shape (GAMLSS) was used to compare a Normal distribution against a Student-t distribution.

Based on the Akaike Information Criterion (AIC), the Student-t distribution was selected as the superior model (AIC: -73,427.45) compared to the Normal distribution (AIC: -71,287.38). The estimated degrees of freedom ($\nu \approx 5.31$) confirm the presence of heavy tails, indicating that the Student-t distribution is more robust to outliers in the marathon dataset. Consequently, all models utilize a log-transformed response variable following a Student-t distribution:

\begin{equation}
    \log(\text{time}_i) \sim \text{Student-t}(\nu, \mu_i, \sigma)
\end{equation}

The log-transformation is applied to ensure the positivity of finishing times and to stabilize the variance across the wide range of performance levels.

\subsection{Baseline Model}

The baseline model serves as the foundation for the analysis, focusing on the fundamental demographic drivers of performance: age and sex. Performance in endurance sports is non-linear with respect to age; athletes typically reach a peak before experiencing a gradual decline. To capture this relationship, a quadratic term for age is included.

\begin{equation}
    \mu_i = \beta_0 + \beta_{\text{sex}} \cdot \text{Sex}_i + \beta_{\text{age}} \cdot \text{Age}_i + \beta_{\text{age2}} \cdot \text{Age}_i^2
\end{equation}

Where:
\begin{itemize}
    \item $\text{Sex}_i$ is a binary indicator (0 for Male, 1 for Female).
    \item $\text{Age}_i$ is the centered age of the runner to reduce collinearity between the linear and quadratic terms.
    \item $\beta_0, \beta_{\text{sex}}, \beta_{\text{age}}, \beta_{\text{age2}}$ are the regression coefficients.
\end{itemize}

Weakly informative priors are assigned to the global parameters to allow the data to dominate the posterior while ensuring numerical stability during the sampling process.

\subsection{Extended Hierarchical Models}

To account for the multi-level nature of the Boston Marathon data, three hierarchical extensions were developed. These models use "partial pooling" to share information across groups, which is more robust than treating each group as independent.

\subsubsection{Model 1: Hierarchical Year Effect}
Marathon times vary year-to-year due to external factors such as temperature, humidity, and wind speed (e.g., the 2012 "heat wave" edition). Rather than treating \texttt{year} as a fixed categorical effect, we model it as a random effect drawn from a global distribution:

\begin{align*}
\mu_i &= \beta_0 + \beta_{\text{sex}} \cdot \text{Sex}_i + \beta_{\text{age}} \cdot \text{Age}_i + \beta_{\text{age2}} \cdot \text{Age}_i^2 + \gamma_{\text{year}}[i] \\
\gamma_{\text{year}_j} &\sim \text{Normal}(0, \sigma_{\text{year}}) \quad \text{for } j = 1 \dots 19
\end{align*}

\subsubsection{Model 2: Hierarchical Country Effect}
Participation in the Boston Marathon is international. Cultural factors, national qualifying standards, and travel distances may influence the performance distribution of runners from different countries. Model 2 extends the hierarchy to include a country-level random effect:

\begin{align*}
\mu_i &= \beta_0 + \dots + \gamma_{\text{year}}[i] + \alpha_{\text{country}}[i] \\
\alpha_{\text{country}_c} &\sim \text{Normal}(0, \sigma_{\text{country}}) \quad \text{for } c = 1 \dots \text{Total Countries}
\end{align*}

\subsubsection{Model 3: Hierarchical Model with Repeated Runners}
The dataset contains many runners who participated in multiple editions of the race. To distinguish between intra-individual changes and inter-individual differences, we created a unique \texttt{ID} for each runner. The identity was reconstructed by grouping observations with the same Name, Sex, City, and calculated Birth Year. This model accounts for the correlation between repeated observations of the same individual:

\begin{align*}
\mu_i &= \beta_0 + \dots + \gamma_{\text{year}}[i] + \alpha_{\text{country}}[i] + \alpha_{\text{runner}}[i] \\
\alpha_{\text{runner}_r} &\sim \text{Normal}(0, \sigma_{\text{runner}}) \quad \text{for } r = 1 \dots \text{Total Unique Runners}
\end{align*}

\subsection{Computation and Implementation}

The models were implemented using Markov Chain Monte Carlo (MCMC) simulations. For each model, multiple chains were run to ensure convergence, monitored via the $\hat{R}$ statistic and visual inspection of trace plots. The final choice between models was based on the Deviance Information Criterion (DIC) and the Root Mean Square Error (RMSE) of the predictions on a validation subset. All data processing and ID generation were performed in Python and R.