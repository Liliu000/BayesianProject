# Codi complet utilitzat pel Treball final de Analisis Bayesia
**Consell: ** utilitzar git-lfs si fas clone del repo. **INTENTAR NO CLONAR, LA MIDA DELS CSVs I MODELS (.rds) ES IMMENSA**

## Datasets utilitzats:
Dintre carpeta **data/** hi ha tots els datasets que es van proposar, els que utilitzem i els datasets transformats que s'utilitza en projecte. 
Dataset originals descarregats de Kaggle i github: 
 - data/Boston_2014-2019: datasets de 2014,2018, 2019 de: https://github.com/adrian3/Boston-Marathon-Data-Project
 - data/og_Boston_2015_2017/: datasets de 2015,2016 i 2017 de: https://www.kaggle.com/datasets/rojour/boston-results
 - els fitxers .csv dintre directament de la carpeta data/ son els creats pels arxius .ipynb. **IMPORTANT**: Tots els models treballen amb **repeated_ids_with_countries.csv**

## Fitxers transformacio de dades:
- clean_Boston2015-2017.ipynb: neteja  i transforma les dades per tenir dades 2015,2016 i 2017 netes i juntes
- clean_Boston2014-18-18.ipynb: neteja i transforma les dades de 2014,2018 i 2019. Tambe transforma dades per unir des de 2014 a 2019 i crear   **repeated_ids_with_countries.csv**
- Plot.Rmd: utilitza dades **repeated_ids_with_countries.csv** per fer exploracio de dades
- script.Rmd: exploracio inicial amb dades nomes de 2015-2017
- CheckNormality.Rmd: crea models GAMLSS per comprobar distribucio temps finals

## Fitser per executar Models:
- RunModels.Rmd: executa model baseline
- RunModels3Extension: executa model amb extensio de efectes climatics de l'any
- Run_Model1_Model2_Model3: executa model 1 (any jerarquic), Model2 (pais jerarquic), Model 3(ID jerarquic)


## Models Bayesians:
Es troben a la carpeta **stan_models/**
- baseModel: Model base amb nomes **edat i sexe**
- Model1: Model amb edat, sexe i efecte d'**any** jerarquic
- Model2: Model amb edat, sexe,efecte d'any jerarquic i efecte **pais** jerarquic
- Model3_simple: Model amb sexe,efecte d'any jerarquic, efecte pais jerarquic i efecte **ID** jerarquic
- Model3: Model amb sexe,efecte d'any jerarquic amd **efectes climatologics** (temperatura, precipitacio, vent), efecte pais jerarquic i efecte ID jerarquic

Cada model te arxiu .rds amb el model ja ajustat:
- baseModel-> fit_model0.rds ¡¡¡ Problema: la versió és antiga, està entranat amb F =1, M = 0 en comptes de F=0, M=1!!
- Model1-> fit_model1.rds
- Model2-> fit_model2.rds
- Model3_simple -> fit_model3.rds
- Model3 -> Model3.rds

## Report:
- Fitxer AB___Final_Assignment.pdf


