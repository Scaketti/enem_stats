library(readxl)
library(dplyr)
library(factoextra)
library(pheatmap)

#Read all datasets
df <- read.csv(file="dataset.csv", sep = ";")

cor_pele <- c('Não declarado','Branca',
              'Preta','Parda','Amarela',
              'Indígena','Não dispõe da informação')
escola <- c('Não respondeu', 'Pública', 'Privada')

df$TP_COR_RACA <- as.factor(df$TP_COR_RACA)
levels(df$TP_COR_RACA) <- cor_pele
df$TP_ESCOLA <- as.factor(df$TP_ESCOLA)
levels(df$TP_ESCOLA) <- escola

a <- df %>% filter(TP_ESCOLA != 'Não respondeu')

row.names(df) <- paste0("row_", seq(nrow(df)))

###### 1 - Estatísticas básicas ######
table(df$TP_SEXO, df$TP_COR_RACA)

notas <- df[c('NU_NOTA_CH','NU_NOTA_MT','NU_NOTA_CN','NU_NOTA_LC','NU_NOTA_REDACAO')]
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

summary(df)

###### 2 - Filtragens ######



###### 3 - Limpeza de dados ######



###### 4 - Gráficos ######

df2 <- df %>%
  group_by(TP_COR_RACA, TP_SEXO) %>%
  summarise(
    n = n(),
    media_CN = mean(NU_NOTA_CN),
    media_CH = mean(NU_NOTA_CH),
    media_LC = mean(NU_NOTA_LC),
    media_MT = mean(NU_NOTA_MT),
    media_redacao = mean(NU_NOTA_REDACAO)
    
  )

# Boxplot média das notas por escola
# Boxplot média das notas por etnia
# Corrplot?
# ?

###### 5 - Testes estatísticos ######

#Comparar notas pelos anos
#

###### 6 - PCA ######

notas <- a[c('NU_NOTA_CH','NU_NOTA_MT','NU_NOTA_CN','NU_NOTA_LC','NU_NOTA_REDACAO')]
notas$NU_NOTA_CH <- notas$NU_NOTA_CH/10
notas$NU_NOTA_MT <- notas$NU_NOTA_MT/10
notas$NU_NOTA_CN <- notas$NU_NOTA_CN/10
notas$NU_NOTA_LC <- notas$NU_NOTA_LC/10

notas.pca <- prcomp(notas, 
       center = TRUE,
       scale. = TRUE)

fviz_pca_biplot(notas.pca, 
                col.ind = as.factor(a$TP_ESCOLA), palette = "jco", 
                addEllipses = TRUE, label = "var",
                col.var = "black", repel = TRUE,
                legend.title = "Tipo Escola"
)

###### 7 - Heatmaps ######



###### 8 - Mapas ######



###### 9 - Clustering ######

dist_scaled <- dist(scale(notas))
fviz_nbclust(notas, kmeans, method = "wss")
k_notas <- kmeans(dist_scaled,centers=6)

df$kmeans <- factor(k_notas$cluster)

grupos_k = data.frame(ID = df[order(df$kmeans),]$kmeans,
                      ESCOLA = df[order(df$kmeans),]$TP_ESCOLA)
cores = list(ID = c("1"="red", "2"="blue","3"="orange", "4"="purple", "5"="black", "6"="pink"))

ordered <- df[order(df$kmeans),c('NU_NOTA_CH','NU_NOTA_MT','NU_NOTA_CN','NU_NOTA_LC','NU_NOTA_REDACAO')]
row.names(ordered) <- row.names(grupos_k)

pheatmap(ordered, cutree_rows = 6,scale = "column",
         cluster_rows = FALSE, cluster_cols = FALSE, 
         annotation_row = grupos_k, annotation_colors = cores, annotation_legend = TRUE)