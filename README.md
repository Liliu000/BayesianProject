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


## Models Bayesians:
Es troben a la carpeta **stan_models/**
- baseModel: Model base amb nomes edat i sexe
- Model3: Model amb extensio de efectes climatics

## Report:
- Fitxer AB___Final_Assignment.pdf


