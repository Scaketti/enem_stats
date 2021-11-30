library(readxl)
library(dplyr)

#Read all datasets
df <- read.csv(file="dataset.csv", sep = ";")

cor_pele <- c('Não declarado','Branca',
              'Preta','Parda','Amarela',
              'Indígena','Não dispõe da informação')
df$TP_COR_RACA <- as.factor(df$TP_COR_RACA)
levels(df$TP_COR_RACA) <- cor_pele


###### 1 - Estatísticas básicas ######
table(df$TP_SEXO, df$TP_COR_RACA)

notas <- df[c('TP_SEXO','TP_COR_RACA','NU_NOTA_CH','NU_NOTA_MT','NU_NOTA_CN','NU_NOTA_LC','NU_NOTA_REDACAO')]
notas$NU_NOTA_CH <- notas$NU_NOTA_CH/10
notas$NU_NOTA_MT <- notas$NU_NOTA_MT/10
notas$NU_NOTA_CN <- notas$NU_NOTA_CN/10
notas$NU_NOTA_LC <- notas$NU_NOTA_LC/10

plot(notas$NU_NOTA_MT, notas$NU_NOTA_REDACAO)

hist(df$NU_IDADE)
quantile(na.omit(df$NU_IDADE))

boxplot(notas$NU_NOTA_CN, notas$NU_NOTA_CH, 
        notas$NU_NOTA_LC, notas$NU_NOTA_MT, 
        notas$NU_NOTA_REDACAO)

###### 2 - Filtragens ######



###### 3 - Limpeza de dados ######



###### 4 - Gráficos ######



###### 5 - Testes estatísticos ######



###### 6 - PCA ######



###### 7 - Heatmaps ######



###### 8 - Mapas ######



###### 9 - Clustering ######



###### 10 - EXTRA ######


