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

cor_pele <- c('Não declarado','Branca',
              'Preta','Parda','Amarela',
              'Indígena','Não dispõe da informação')
escola <- c('Não respondeu', 'Pública', 'Privada')
renda <- c('Nenhuma renda', 'Ate R$ 788', 'R$ 788,01 ate R$ 1.182',
           'De R$ 1.182,01 ate R$ 1.572', 'De R$ 1.572,01 ate R$ 1.970',
           'De R$ 1.970,01 até R$ 2.364', 'De R$ 2.364,01 até R$ 3.152',
           'De R$ 3.152,01 até R$ 3.940', 'De R$ 3.940,01 até R$ 4.728',
           'De R$ 4.728,01 até R$ 5.516', 'De R$ 5.516,01 até R$ 6.304',
           'De R$ 6.304,01 até R$ 7.092', 'De R$ 7.092,01 até R$ 7.880',
           'De R$ 7.880,01 até R$ 9.456', 'De R$ 9.456,01 até R$ 11.820',
           'De R$ 11.820,01 até R$ 15.760', 'Mais de 15.760')

df$TP_COR_RACA <- as.factor(df$TP_COR_RACA)
levels(df$TP_COR_RACA) <- cor_pele
df$TP_ESCOLA <- as.factor(df$TP_ESCOLA)
levels(df$TP_ESCOLA) <- escola

df$Q001 <- as.factor(df$Q001)
df$Q002 <- as.factor(df$Q002)
df$Q005 <- as.factor(df$Q005)

#limpando erros
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

###### 1 - Estatísticas básicas ######
summary(df)
table(df$TP_SEXO, df$TP_COR_RACA)
table(df$TP_ESCOLA, df$TP_COR_RACA)

plot(notas$NU_NOTA_MT, notas$NU_NOTA_REDACAO)

hist(df$NU_IDADE)
quantile(na.omit(df$NU_IDADE))

boxplot(notas$NU_NOTA_CN, notas$NU_NOTA_CH, 
        notas$NU_NOTA_LC, notas$NU_NOTA_MT, 
        notas$NU_NOTA_REDACAO)

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

df <- df_na %>% filter(TP_ESCOLA != 'Não respondeu') %>% 
  filter(TP_COR_RACA != 'Não declarado' & TP_COR_RACA != 'Não dispõe da informação')

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

###### 4 - Gráficos ######

ggplot(data = df_clean, aes(x=TP_COR_RACA, y=NU_NOTA_REDACAO,fill=TP_SEXO)) + 
  geom_boxplot(outlier.shape = NA)+
  xlab("Etnia")+ylab("Média redacao")

bp1 <- ggplot(data = df_clean, aes(x=TP_COR_RACA, y=NU_NOTA_REDACAO,fill=TP_ESCOLA)) + 
  geom_boxplot(outlier.shape = NA)+
  xlab("Etnia")+ylab("Média redacao")+ggtitle("Médias de notas de redação por tipo de escola")

bp2 <- ggplot(data = df_clean, aes(x=TP_COR_RACA, y=NU_NOTA_REDACAO,fill=Q006)) + 
  geom_boxplot(outlier.shape = NA)+
  xlab("Etnia")+ylab("Média redacao")

table(df_clean$TP_ESCOLA, df_clean$TP_COR_RACA)

grid.arrange(bp1, bp2, nrow=2)

# Corrplot?
# ?

###### 5 - Testes estatísticos ######

df_teste <- data.frame(
  media2015 = apply((df_clean %>% filter(NU_ANO == 2015))[,c(8:12)], 1, mean)[1:594],
  media2016 = apply((df_clean %>% filter(NU_ANO == 2016))[,c(8:12)], 1, mean)[1:594],
  media2017 = apply((df_clean %>% filter(NU_ANO == 2017))[,c(8:12)], 1, mean)[1:594],
  media2018 = apply((df_clean %>% filter(NU_ANO == 2018))[,c(8:12)], 1, mean)[1:594],
  media2019 = apply((df_clean %>% filter(NU_ANO == 2019))[,c(8:12)], 1, mean)[1:594]
)

#Comparar notas pelos anos
model  <- lm(df_teste)
ggqqplot(residuals(model))
ggqqplot(df_teste, "media2015", facet.by = "media2019")
shapiro.test(residuals(model))

with(data,tapply(media2015,media2019,shapiro.test))

## Homogenidade (Variancias iguais)
plot(model, 1)

library(car) #carrega a funcao leveneTest
leveneTest(df_teste,center=median)
# Como p < 0.05, ha diferenca na variancia

kruskal.test(df_teste) 
#

###### 6 - PCA ######

notas <- df_clean[c('NU_NOTA_CH','NU_NOTA_MT','NU_NOTA_CN','NU_NOTA_LC','NU_NOTA_REDACAO')]

notas.pca <- prcomp(notas, 
                    center = TRUE,
                    scale. = TRUE)

fviz_pca_biplot(notas.pca, 
                col.ind = as.factor(df_clean$TP_ESCOLA), palette = "jco", 
                addEllipses = TRUE, label = "var",
                col.var = "black", repel = TRUE,
                legend.title = "Tipo Escola"
)

###### 7 - Heatmaps ######

pheatmap(notas,cutree_rows=3, scale = "column",
         cluster_rows = TRUE,cluster_cols = FALSE)

###### 8 - Mapas ######
no_axis <- theme(axis.title=element_blank(),
                 axis.text=element_blank(),
                 axis.ticks=element_blank())

states <- read_state(year=2020)

df_clean$SG_UF_RESIDENCIA <- as.factor(df_clean$SG_UF_RESIDENCIA)
states$abbrev_state <- tolower(states$abbrev_state)
df_clean$SG_UF_RESIDENCIA <- tolower(df_clean$SG_UF_RESIDENCIA)


df_media_2015 <- df_clean %>% 
  filter(NU_ANO == 2015, NU_NOTA_MEDIA > 500, TP_ESCOLA == 'Pública') %>%
  group_by(SG_UF_RESIDENCIA) %>%
  summarise(
    n = n()
  )
df_media_2016 <- df_clean %>% 
  filter(NU_ANO == 2016, NU_NOTA_MEDIA > 500, TP_ESCOLA == 'Pública') %>%
  group_by(SG_UF_RESIDENCIA) %>%
  summarise(
    n = n()
  )
df_media_2017 <- df_clean %>% 
  filter(NU_ANO == 2017, NU_NOTA_MEDIA > 500, TP_ESCOLA == 'Pública') %>%
  group_by(SG_UF_RESIDENCIA) %>%
  summarise(
    n = n()
  )
df_media_2018 <- df_clean %>% 
  filter(NU_ANO == 2018, NU_NOTA_MEDIA > 500, TP_ESCOLA == 'Pública') %>%
  group_by(SG_UF_RESIDENCIA) %>%
  summarise(
    n = n()
  )
df_media_2019 <- df_clean %>% 
  filter(NU_ANO == 2019, NU_NOTA_MEDIA > 500, TP_ESCOLA == 'Pública') %>%
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
  scale_fill_distiller(palette = "Blues", name="N° Alunos", limits = c(min(states_2015$n),max(states_2015$n)+10)) +
  theme_minimal() +
  no_axis
m2<-ggplot() +
  geom_sf(data=states_2016, aes(fill=n), color= NA, size=.15) +
  labs(subtitle="2016", size=8) +
  scale_fill_distiller(palette = "Blues", name="N° Alunos", limits = c(min(states_2015$n),max(states_2015$n)+10)) +
  theme_minimal() +
  no_axis
m3<-ggplot() +
  geom_sf(data=states_2017, aes(fill=n), color= NA, size=.15) +
  labs(subtitle="2017", size=8) +
  scale_fill_distiller(palette = "Blues", name="N° Alunos", limits = c(min(states_2015$n),max(states_2015$n)+10)) +
  theme_minimal() +
  no_axis
m4<-ggplot() +
  geom_sf(data=states_2018, aes(fill=n), color= NA, size=.15) +
  labs(subtitle="2018", size=8) +
  scale_fill_distiller(palette = "Blues", name="N° Alunos", limits = c(min(states_2015$n),max(states_2015$n)+10)) +
  theme_minimal() +
  no_axis
m5<-ggplot() +
  geom_sf(data=states_2019, aes(fill=n), color= NA, size=.15) +
  labs(subtitle="2019", size=8) +
  scale_fill_distiller(palette = "Blues", name="N° Alunos", limits = c(min(states_2015$n),max(states_2015$n)+10)) +
  theme_minimal() +
  no_axis

grid.arrange(m1,m2,m3,m4,m5, 
             nrow=3, top=textGrob("Alunos de escola pública com nota > 500 (2015 ~ 2019)"))

###### 9 - Clustering ######

dist_scaled <- dist(scale(notas))
fviz_nbclust(notas, kmeans, method = "wss")
k_notas <- kmeans(dist_scaled,centers=3)

df_clean$kmeans <- factor(k_notas$cluster)

grupos_k = data.frame(ID = df_clean[order(df_clean$kmeans),]$kmeans,
                      ESCOLA = df_clean[order(df_clean$kmeans),]$TP_ESCOLA)
#cores = list(ID = c("1"="red", "2"="blue","3"="orange", "4"="purple", "5"="black", "6"="pink"))
cores = list(ID = c("1"="red", "2"="blue","3"="orange"),
                   ESCOLA = c("Pública"="purple", "Privada"="black"))
ordered <- df_clean[order(df_clean$kmeans),c('NU_NOTA_CH','NU_NOTA_MT','NU_NOTA_CN','NU_NOTA_LC','NU_NOTA_REDACAO')]
row.names(ordered) <- row.names(grupos_k)

pheatmap(ordered, cutree_rows = 3,scale = "column",
         cluster_rows = FALSE, cluster_cols = FALSE, 
         annotation_row = grupos_k, annotation_colors = cores, annotation_legend = TRUE)
