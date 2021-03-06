library(readxl)
library(dplyr)
library(factoextra)
library(pheatmap)
library(gridExtra)
library(grid)
library(reshape2)
library(ggpubr)
library(geobr)

#Read all datasets
df <- read.csv(file="dataset.csv", sep = ";")

cor_pele <- c('N�o declarado','Branca',
              'Preta','Parda','Amarela',
              'Ind�gena','N�o disp�e da informa��o')
escola <- c('N�o respondeu', 'P�blica', 'Privada')
renda <- c('Nenhuma renda', 'Ate R$ 788', 'R$ 788,01 ate R$ 1.182',
           'De R$ 1.182,01 ate R$ 1.572', 'De R$ 1.572,01 ate R$ 1.970',
           'De R$ 1.970,01 at� R$ 2.364', 'De R$ 2.364,01 at� R$ 3.152',
           'De R$ 3.152,01 at� R$ 3.940', 'De R$ 3.940,01 at� R$ 4.728',
           'De R$ 4.728,01 at� R$ 5.516', 'De R$ 5.516,01 at� R$ 6.304',
           'De R$ 6.304,01 at� R$ 7.092', 'De R$ 7.092,01 at� R$ 7.880',
           'De R$ 7.880,01 at� R$ 9.456', 'De R$ 9.456,01 at� R$ 11.820',
           'De R$ 11.820,01 at� R$ 15.760', 'Mais de 15.760')
escolaridade <- c('Nunca estudou',
                  'N�o completou a 4� s�rie/5� ano do Ensino Fundamental',
                  'Completou a 4� s�rie/5� ano, mas n�o completou a 8� s�rie/9� ano do Ensino Fundamental',
                  'Completou a 8� s�rie/9� ano do Ensino Fundamental, mas n�o completou o Ensino M�dio',
                  'Completou o Ensino M�dio, mas n�o completou a Faculdade',
                  'Completou a Faculdade, mas n�o completou a P�s-gradua��o',
                  'Completou a P�s-gradua��o',
                  'N�o sei')

df$TP_COR_RACA <- as.factor(df$TP_COR_RACA)
levels(df$TP_COR_RACA) <- cor_pele
df$TP_ESCOLA <- as.factor(df$TP_ESCOLA)
levels(df$TP_ESCOLA) <- escola

df$NU_ANO <- as.factor(df$NU_ANO)
df$Q005 <- as.factor(df$Q005)

#limpando erros
df <- df[df$Q001 != '',]
df$Q001 <- as.factor(df$Q001)
levels(df$Q001) <- escolaridade
df <- df[df$Q002 != '',]
df$Q002 <- as.factor(df$Q002)
levels(df$Q002) <- escolaridade
df <- df[df$Q006 != '',]
df$Q006 <- as.factor(df$Q006)
levels(df$Q006) <- renda

df$NU_NOTA_CH <- df$NU_NOTA_CH/10
df$NU_NOTA_MT <- df$NU_NOTA_MT/10
df$NU_NOTA_CN <- df$NU_NOTA_CN/10
df$NU_NOTA_LC <- df$NU_NOTA_LC/10

df$NU_NOTA_MEDIA <- (df$NU_NOTA_CH+df$NU_NOTA_CN+df$NU_NOTA_LC+df$NU_NOTA_MT+df$NU_NOTA_REDACAO)/5

row.names(df) <- paste0("row_", seq(nrow(df)))

#limpando colunas indesejadas
df <- df[,-c(1,4, 6:8, 11, 13,14,20)]

###### 1 - Estat�sticas b�sicas ######
summary(df)
table(df$TP_SEXO, df$TP_COR_RACA)
table(df$TP_ESCOLA, df$TP_COR_RACA)

plot(df$NU_NOTA_MT, df$NU_NOTA_REDACAO)

hist(df$NU_IDADE)
quantile(na.omit(df$NU_IDADE))

boxplot(df$NU_NOTA_CN, df$NU_NOTA_CH, 
        df$NU_NOTA_LC, df$NU_NOTA_MT, 
        df$NU_NOTA_REDACAO)

###### 2 - Filtragens ######

# retirar na
df_na <- na.omit(df)

df2 <- df_na %>%
  group_by(TP_SEXO, TP_COR_RACA) %>%
  summarise(
    n = n(),
    media_CN = mean(NU_NOTA_CN,
    media_CH = mean(NU_NOTA_CH),
    media_LC = mean(NU_NOTA_LC),
    media_MT = mean(NU_NOTA_MT),
    media_redacao = mean(NU_NOTA_REDACAO)
  ))

df <- df_na %>% filter(TP_ESCOLA != 'N�o respondeu') %>% 
  filter(TP_COR_RACA != 'N�o declarado' & TP_COR_RACA != 'N�o disp�e da informa��o')

###### 3 - Limpeza de dados ######
#veriricar se existem NAs
is.na(df)
table(is.na(df)) # tabela de frequencia 

#Detectando outlier 
outlier_values_1 <- boxplot.stats(df$NU_NOTA_REDACAO)$out
outlier_values_2 <- boxplot.stats(df$NU_NOTA_CN)$out
outlier_values_3 <- boxplot.stats(df$NU_NOTA_CH)$out
outlier_values_4 <- boxplot.stats(df$NU_NOTA_LC)$out
outlier_values_5 <- boxplot.stats(df$NU_NOTA_MT)$out

#verifica
library(EnvStats)
test <- rosnerTest(df$NU_NOTA_REDACAO,k=length(outlier_values_1),alpha = 0.05)
test <- rosnerTest(df$NU_NOTA_CN,k=length(outlier_values_2),alpha = 0.05)
test <- rosnerTest(df$NU_NOTA_CH,k=length(outlier_values_3),alpha = 0.05)
test <- rosnerTest(df$NU_NOTA_LC,k=length(outlier_values_4),alpha = 0.05)
test <- rosnerTest(df$NU_NOTA_MT,k=length(outlier_values_5),alpha = 0.05)

outliers <- unique(c(outlier_values_1, outlier_values_2, 
                     outlier_values_3, outlier_values_4, outlier_values_5))

#retira outliers de todas as colunas de notas
df_clean <- df[-which(df$NU_NOTA_REDACAO %in% outlier_values_1 |
                      df$NU_NOTA_CN %in% outlier_values_2 |
                      df$NU_NOTA_CH %in% outlier_values_3 |
                      df$NU_NOTA_LC %in% outlier_values_4 |
                      df$NU_NOTA_MT %in% outlier_values_5),]

###### 4 - Gr�ficos ######

ggplot(data = df_clean, aes(x=TP_COR_RACA, y=NU_NOTA_MEDIA,fill=TP_SEXO)) + 
  geom_boxplot(outlier.shape = NA)+
  xlab("Etnia")+ylab("M�dia nota enem")+ggtitle("M�dia notas do enem por sexo e ra�a")+
  stat_compare_means(label.y = c(800),
                     method = "wilcox.test",paired = FALSE)

bp1 <- ggplot(data = df_clean, aes(x=TP_COR_RACA, y=NU_NOTA_MEDIA,fill=TP_ESCOLA)) + 
  geom_boxplot(outlier.shape = NA)+
  xlab("Etnia")+ylab("M�dia nota enem")+ggtitle("M�dias de notas do enem por tipo de escola")+
  stat_compare_means(label.y = c(800),
                     method = "wilcox.test",paired = FALSE)

bp2 <- ggplot(data = df_clean, aes(x=TP_COR_RACA, y=NU_NOTA_MEDIA,fill=Q006)) + 
  geom_boxplot(outlier.shape = NA)+
  xlab("Etnia")+ylab("M�dia nota enem")

grid.arrange(bp1, bp2, nrow=2)

ggplot(df_clean, aes(x=NU_NOTA_MEDIA, fill=Q001)) + 
  geom_density(alpha=.5) +
  theme(legend.position = "right")+
  ggtitle("M�dia de notas em rela��o a escolaridade da m�e")

###### 5 - Testes estat�sticos ######

## Kruskalwallis durante anos ##
model  <- lm(NU_NOTA_MEDIA ~ NU_ANO, data = df_clean)
ggqqplot(residuals(model))
ggqqplot(df_clean, "NU_NOTA_MEDIA", facet.by = "NU_ANO")
shapiro.test(residuals(model))

with(df_clean,tapply(NU_NOTA_MEDIA,NU_ANO,shapiro.test))

plot(model, 1)

library(car) #carrega a funcao leveneTest
leveneTest(NU_NOTA_MEDIA ~ NU_ANO,data = df_clean,center=median)
# Como p < 0.05, ha diferenca na variancia

#H0 -> notas mantem o mesmo durante os anos?
#p-value > 0.05 (0.1424)
#Aceiramos a hip�tese (n�o melhora durante os anos)
kruskal.test(NU_NOTA_MEDIA ~ NU_ANO, data = df_clean)

## Mann U test possuir pais e maes com escolaridade ajuda sua nota? ##

df_escolaridade_baixa <- df_clean %>% filter(TP_ESCOLA == 'P�blica', 
          Q001 %in% c('Nunca estudou',
                      'N�o completou a 4� s�rie/5� ano do Ensino Fundamental',
                      'Completou a 4� s�rie/5� ano, mas n�o completou a 8� s�rie/9� ano do Ensino Fundamental',
                      'Completou a 8� s�rie/9� ano do Ensino Fundamental, mas n�o completou o Ensino M�dio'),
          Q002 %in% c('Nunca estudou',
                      'N�o completou a 4� s�rie/5� ano do Ensino Fundamental',
                      'Completou a 4� s�rie/5� ano, mas n�o completou a 8� s�rie/9� ano do Ensino Fundamental',
                      'Completou a 8� s�rie/9� ano do Ensino Fundamental, mas n�o completou o Ensino M�dio')
          )
df_escolaridade_alto <- df_clean %>% filter(TP_ESCOLA == 'P�blica',
          Q001 %in% c('Completou o Ensino M�dio, mas n�o completou a Faculdade',
                      'Completou a Faculdade, mas n�o completou a P�s-gradua��o',
                      'Completou a P�s-gradua��o'),
          Q002 %in% c('Completou o Ensino M�dio, mas n�o completou a Faculdade',
                      'Completou a Faculdade, mas n�o completou a P�s-gradua��o',
                      'Completou a P�s-gradua��o'))
df_escolaridade <- data.frame()

#h0 -> possuir pais com melhor escolaridade te ajuda a tirar melhor nota
#p-value < 0.05 (3.268e-16) rejeita H0
wilcox.test(df_escolaridade_baixa$NU_NOTA_MEDIA, df_escolaridade_alto$NU_NOTA_MEDIA,exact = FALSE,
                   paired = FALSE)

###### 6 - PCA ######

notas_geral <- df_clean[,8:12]

notas_geral.pca <- prcomp(notas_geral, 
                    center = TRUE,
                    scale. = TRUE)

fviz_pca_biplot(notas_geral.pca, 
                col.ind = as.factor(df_clean$TP_ESCOLA), palette = "jco", 
                addEllipses = TRUE, label = "var",
                col.var = "black", repel = TRUE,
                legend.title = "Tipo Escola"
)

###### 7 - Heatmaps ######

pheatmap(notas_geral,cutree_rows=3, scale = "column",
         cluster_rows = TRUE,cluster_cols = FALSE, 
         main="Rela��o de notas de alunos do enem (2015 ~ 2019)")

df_publica <- df_clean[df_clean$TP_ESCOLA == 'P�blica',]

grupos_heat = data.frame(RACA = df_publica$TP_COR_RACA,
                      RENDA = df_publica$Q006)

rownames(grupos_heat) <- rownames(df_publica)

#mapeia as cores para cada tipo de renda
cores_renda <- c(rep("purple", 3), rep("black", 4), rep("cyan",6), rep("yellow", 4))
names(cores_renda) <- renda

cores_heat = list(RACA = c("Branca"="red", "Preta"="blue",
                           "Parda"="orange", "Amarela"="cyan", "Ind�gena"="purple"),
                  RENDA = c(cores_renda))
#geral
pheatmap(df_publica[,c(8:12)], cutree_rows = 3, scale = "column", 
         annotation_row = grupos_heat, annotation_colors = cores_heat,
         cluster_rows = TRUE,cluster_cols = FALSE, annotation_legend = TRUE,
         main="Rela��o de notas de alunos de escola p�blica (2015 ~ 2019)")

#ano 2019
pheatmap(df_publica[df_publica$NU_ANO==2019,c(8:12)], cutree_rows = 3, scale = "column", 
         annotation_row = grupos_heat, annotation_colors = cores_heat,
         cluster_rows = TRUE,cluster_cols = FALSE, annotation_legend = TRUE,
         main="Rela��o de notas de alunos de escola p�blica (2019)")

###### 8 - Mapas ######
no_axis <- theme(axis.title=element_blank(),
                 axis.text=element_blank(),
                 axis.ticks=element_blank())

states <- read_state(year=2020)

df_clean$SG_UF_RESIDENCIA <- as.factor(df_clean$SG_UF_RESIDENCIA)
states$abbrev_state <- tolower(states$abbrev_state)
df_clean$SG_UF_RESIDENCIA <- tolower(df_clean$SG_UF_RESIDENCIA)


df_media_2015 <- df_clean %>% 
  filter(NU_ANO == 2015, NU_NOTA_MEDIA > 500, TP_ESCOLA == 'P�blica') %>%
  group_by(SG_UF_RESIDENCIA) %>%
  summarise(
    n = n()
  )
df_media_2016 <- df_clean %>% 
  filter(NU_ANO == 2016, NU_NOTA_MEDIA > 500, TP_ESCOLA == 'P�blica') %>%
  group_by(SG_UF_RESIDENCIA) %>%
  summarise(
    n = n()
  )
df_media_2017 <- df_clean %>% 
  filter(NU_ANO == 2017, NU_NOTA_MEDIA > 500, TP_ESCOLA == 'P�blica') %>%
  group_by(SG_UF_RESIDENCIA) %>%
  summarise(
    n = n()
  )
df_media_2018 <- df_clean %>% 
  filter(NU_ANO == 2018, NU_NOTA_MEDIA > 500, TP_ESCOLA == 'P�blica') %>%
  group_by(SG_UF_RESIDENCIA) %>%
  summarise(
    n = n()
  )
df_media_2019 <- df_clean %>% 
  filter(NU_ANO == 2019, NU_NOTA_MEDIA > 500, TP_ESCOLA == 'P�blica') %>%
  group_by(SG_UF_RESIDENCIA) %>%
  summarise(
    n = n()
  )

states_2015 <- dplyr::left_join(states, df_media_2015, by = c("abbrev_state" = "SG_UF_RESIDENCIA"))
states_2016 <- dplyr::left_join(states, df_media_2016, by = c("abbrev_state" = "SG_UF_RESIDENCIA"))
states_2017 <- dplyr::left_join(states, df_media_2017, by = c("abbrev_state" = "SG_UF_RESIDENCIA"))
states_2018 <- dplyr::left_join(states, df_media_2018, by = c("abbrev_state" = "SG_UF_RESIDENCIA"))
states_2019 <- dplyr::left_join(states, df_media_2019, by = c("abbrev_state" = "SG_UF_RESIDENCIA"))

m1<-ggplot() +
  geom_sf(data=states_2015, aes(fill=n), color= NA, size=.15) +
  labs(subtitle="2015", size=8) +
  scale_fill_distiller(palette = "Blues", name="N� Alunos", limits = c(min(states_2015$n),max(states_2015$n)+10)) +
  theme_minimal() +
  no_axis
m2<-ggplot() +
  geom_sf(data=states_2016, aes(fill=n), color= NA, size=.15) +
  labs(subtitle="2016", size=8) +
  scale_fill_distiller(palette = "Blues", name="N� Alunos", limits = c(min(states_2015$n),max(states_2015$n)+10)) +
  theme_minimal() +
  no_axis
m3<-ggplot() +
  geom_sf(data=states_2017, aes(fill=n), color= NA, size=.15) +
  labs(subtitle="2017", size=8) +
  scale_fill_distiller(palette = "Blues", name="N� Alunos", limits = c(min(states_2015$n),max(states_2015$n)+10)) +
  theme_minimal() +
  no_axis
m4<-ggplot() +
  geom_sf(data=states_2018, aes(fill=n), color= NA, size=.15) +
  labs(subtitle="2018", size=8) +
  scale_fill_distiller(palette = "Blues", name="N� Alunos", limits = c(min(states_2015$n),max(states_2015$n)+10)) +
  theme_minimal() +
  no_axis
m5<-ggplot() +
  geom_sf(data=states_2019, aes(fill=n), color= NA, size=.15) +
  labs(subtitle="2019", size=8) +
  scale_fill_distiller(palette = "Blues", name="N� Alunos", limits = c(min(states_2015$n),max(states_2015$n)+10)) +
  theme_minimal() +
  no_axis

grid.arrange(m1,m2,m3,m4,m5, 
             nrow=3, top=textGrob("Alunos de escola p�blica com nota > 500 (2015 ~ 2019)"))

###### 9 - Clustering ######

dist_scaled <- dist(scale(notas_geral))
fviz_nbclust(notas_geral, kmeans, method = "wss")
k_notas <- kmeans(dist_scaled,centers=3)

df_clean$kmeans <- factor(k_notas$cluster)

grupos_k = data.frame(ID = df_clean[order(df_clean$kmeans),]$kmeans,
                      ESCOLA = df_clean[order(df_clean$kmeans),]$TP_ESCOLA)
#cores = list(ID = c("1"="red", "2"="blue","3"="orange", "4"="purple", "5"="black", "6"="pink"))
cores_k = list(ID = c("1"="red", "2"="blue","3"="orange"),
                   ESCOLA = c("P�blica"="purple", "Privada"="black"))
ordered <- df_clean[order(df_clean$kmeans),c('NU_NOTA_CH','NU_NOTA_MT','NU_NOTA_CN','NU_NOTA_LC','NU_NOTA_REDACAO')]
row.names(ordered) <- row.names(grupos_k)

pheatmap(ordered, cutree_rows = 3,scale = "column",
         cluster_rows = FALSE, cluster_cols = FALSE, 
         annotation_row = grupos_k, annotation_colors = cores_k, annotation_legend = TRUE)
