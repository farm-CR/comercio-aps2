library(tidyverse)
library(fixest)
library(modelsummary)

mercosul <- c("BRA", "ARG", "URY", "PRY")

df <- bind_rows(
  read_csv("dados/Isic_bilateral_trade_1.csv"),
  read_csv("dados/Isic_bilateral_trade_2.csv"),
  read_csv("dados/Isic_bilateral_trade_3.csv"),
  read_csv("dados/Isic_bilateral_trade_4.csv"),
  read_csv("dados/Isic_bilateral_trade_5.csv")) %>% 
  left_join(read_csv("dados/distance.csv")) %>% 
  left_join(read_csv("dados/languages.csv") %>% 
              select(ccode, pcode, com_lang)) %>% 
  left_join(read_csv("dados/GDP.csv") %>% 
              select(ccode, year, cpib = gdp_current)) %>% 
  left_join(read_csv("dados/GDP.csv") %>% 
              select(pcode = ccode, year, ppib = gdp_current)) %>% 
  mutate(mercosul_intra = ifelse(year >= 1991 & (ccode %in% mercosul & pcode %in% mercosul), TRUE, FALSE),
         mercosul_mundo = ifelse(year >= 1991 & (ccode %in% mercosul | pcode %in% mercosul), TRUE, FALSE))

#Quest�o 1 ----
df %>%
  mutate(tipo = ifelse(mercosul_intra == 1, "Intra Mercosul",
                       ifelse(mercosul_mundo == 1, "Mercosul Mundo", "Resto do Mundo"))) %>% 
  group_by(year, tipo) %>% 
  summarize(importacoes = sum(imp_tv)) %>% 
  arrange(year) %>% 
  group_by(tipo) %>% 
  mutate(variacao = (importacoes - lag(importacoes))/(lag(importacoes))) %>% 
  ungroup() %>%
  filter(year > 1990) %>% 
  ggplot(aes(x = year, y = variacao, color = tipo)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point() +
  geom_line() +
  labs(x = "Ano", y = "Varia��o (%) no volume de Importa��es", color = "Dire��o do com�rcio") +
  scale_y_continuous(labels = scales::percent)

#Quest�o 2 ----
feols(log(imp_tv) ~ log(cpib) + log(ppib) + log(km) + 
        mercosul_intra + mercosul_mundo + com_lang | ccode + pcode + year, 
      data = df)

#Quest�o 3 ----
feols(log(imp_tv) ~ log(cpib) + log(ppib) + log(km) + com_lang + factor(year) * (mercosul_intra + mercosul_mundo)| ccode + pcode, 
      data = df %>% filter(year > 1990)) %>% 
  modelplot(coef_map = c("factor(year)1992:mercosul_intraTRUE" = 1992,
                         "factor(year)1993:mercosul_intraTRUE" = 1993,
                         "factor(year)1994:mercosul_intraTRUE" = 1994,
                         "factor(year)1995:mercosul_intraTRUE" = 1995,
                         "factor(year)1996:mercosul_intraTRUE" = 1996,
                         "factor(year)1997:mercosul_intraTRUE" = 1997,
                         "factor(year)1998:mercosul_intraTRUE" = 1998,
                         "factor(year)1999:mercosul_intraTRUE" = 1999,
                         "factor(year)2000:mercosul_intraTRUE" = 2000,
                         "factor(year)2001:mercosul_intraTRUE" = 2001,
                         "factor(year)2002:mercosul_intraTRUE" = 2002,
                         "factor(year)2003:mercosul_intraTRUE" = 2003,
                         "factor(year)2004:mercosul_intraTRUE" = 2004)) +
  
  coord_flip() +
  labs(x = "Coeficiente da intera��o MERCOSUL-ano", y = "Ano")


feols(log(imp_tv) ~ log(cpib) + log(ppib) + log(km) + 
        mercosul_intra + mercosul_mundo + com_lang + log(exp_tv) : mercosul_mundo | ccode + pcode + year, 
      data = df)
