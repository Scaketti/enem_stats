library(readxl)
library(dplyr)
library(factoextra)
library(pheatmap)

#Read all datasets
df <- read.csv(file="dataset.csv", sep = ";")

cor_pele <- c('NÃ£o declarado','Branca',
              'Preta','Parda','Amarela',
              'IndÃ­gena','NÃ£o dispÃµe da informaÃ§Ã£o')
escola <- c('NÃ£o respondeu', 'PÃºblica', 'Privada')

df$TP_COR_RACA <- as.factor(df$TP_COR_RACA)
levels(df$TP_COR_RACA) <- cor_pele
df$TP_ESCOLA <- as.factor(df$TP_ESCOLA)
levels(df$TP_ESCOLA) <- escola
df$Q001 <- as.factor(df$Q001)
df$Q002 <- as.factor(df$Q002)
df$Q005 <- as.factor(df$Q005)
df$Q006 <- as.factor(df$Q006)


row.names(df) <- paste0("row_", seq(nrow(df)))

###### 1 - EstatÃ­sticas bÃ¡sicas ######
summary(df)
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

###### 2 - Filtragens ######

df2 <- df_na %>%
  group_by(TP_SEXO, TP_COR_RACA) %>%
  summarise(
    n = n(),
    media_CN = mean(NU_NOTA_CN),
    media_CH = mean(NU_NOTA_CH),
    media_LC = mean(NU_NOTA_LC),
    media_MT = mean(NU_NOTA_MT),
    media_redacao = mean(NU_NOTA_REDACAO)
  )

df2 <- df_na %>%
  group_by(TP_SEXO, TP_COR_RACA) %>%
  summarise(
    n = n(),
    media_CN = mean(NU_NOTA_CN),
    media_CH = mean(NU_NOTA_CH),
    media_LC = mean(NU_NOTA_LC),
    media_MT = mean(NU_NOTA_MT),
    media_redacao = mean(NU_NOTA_REDACAO)
  )


###### 3 - Limpeza de dados ######
#veriricar se existem NAs
is.na(df)
table(is.na(df)) # tabela de frequencia 

# retirar na
df_na <- na.omit(df)

#Detectando outlier 
outlier_values_1 <- boxplot.stats(df_na$NU_NOTA_REDACAO)$out
outlier_values_2 <- boxplot.stats(df_na$NU_NOTA_CN)$out
outlier_values_3 <- boxplot.stats(df_na$NU_NOTA_CH)$out
outlier_values_4 <- boxplot.stats(df_na$NU_NOTA_LC)$out
outlier_values_5 <- boxplot.stats(df_na$NU_NOTA_MT)$out

#verifica
library(EnvStats)
test <- rosnerTest(df_na$NU_NOTA_REDACAO,k=length(outlier_values_1),alpha = 0.05)
test <- rosnerTest(df_na$NU_NOTA_CN,k=length(outlier_values_2),alpha = 0.05)
test <- rosnerTest(df_na$NU_NOTA_CH,k=length(outlier_values_3),alpha = 0.05)
test <- rosnerTest(df_na$NU_NOTA_LC,k=length(outlier_values_4),alpha = 0.05)
test <- rosnerTest(df_na$NU_NOTA_MT,k=length(outlier_values_5),alpha = 0.05)


#retira
df_clean_1 <- df_na[-which(df_na$NU_NOTA_REDACAO %in% outlier_values_1),]
df_clean_2 <- df_na[-which(df_na$NU_NOTA_CN %in% outlier_values_2),]
df_clean_3 <- df_na[-which(df_na$NU_NOTA_CH %in% outlier_values_3),]
df_clean_4 <- df_na[-which(df_na$df_na$NU_NOTA_Lc %in% outlier_values_4),]
df_clean_5 <- df_na[-which(df_na$NU_NOTA_MT %in% outlier_values_5),]

###### 4 - GrÃ¡ficos ######

ggplot(data = df_clean, aes(x=df_clean$TP_COR_RACA, y=df_clean$NU_NOTA_REDACAO,fill=df_clean$TP_SEXO)) + 
  geom_boxplot(outlier.shape = NA)+
  xlab("Etnia")+ylab("Média redacao")

ggplot(data = df_clean, aes(x=df_clean$TP_COR_RACA, y=df_clean$NU_NOTA_REDACAO,fill=df_clean$Q006)) + 
  geom_boxplot(outlier.shape = NA)+
  xlab("Etnia")+ylab("Média redacao")


###### 5 - Testes estatÃ­sticos ######



###### 6 - PCA ######

notas.pca <- prcomp(notas[, c(3:7)], 
       center = TRUE,
       scale. = TRUE)


fviz_pca_biplot(notas.pca, 
                col.ind = df$TP_ESCOLA, palette = "jco", 
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


###### 10 - EXTRA ######


