#!/usr/bin/env Rscript
suppressMessages(library(tidyverse))
suppressMessages(library(dplyr))
suppressMessages(library(ggplot2))
suppressMessages(library(lubridate))

get_denuncies <- function() {
  denuncies <- list.files(path = "/home/xavier/programming/R/delictes", pattern = "*b.csv", full.names=TRUE) %>% map_df(~read.csv2(.))
  names(denuncies) <- c("Numero", "Mes", "Any", "Regio", "ABP", "CodiPenal", "Delicte", "Coneguts", "Resolts", "Detencions")
  denuncies
}


args = commandArgs(trailingOnly=TRUE)
if (length(args) == 0 || length(args) > 2) {
  "Help?"
  stop("Almenys has d'especificar 'helpABP', per veure els ABP, 'helpDelictes', per veure els delictes, el delicte a mostrar (delicte) o (el delicte i l'ABP)", call.=FALSE)
}

denuncies <-get_denuncies()

if (args[1] == "helpABP") {
  resultat <- (denuncies %>% distinct(ABP) %>% mutate(ABP=gsub("ABP ", "", ABP)))
} else if (args[1] == "helpDelictes") {
  resultat <- denuncies %>% distinct(Delicte)

} else {

    elDelicte <- args[1]

    if (length(args) == 1) {

        denuncies_agrupades <- denuncies %>% select(Any, Numero, Mes, Delicte, Coneguts, Resolts, Detencions) %>% mutate_if(is.numeric, funs(ifelse(is.na(.), 0, .))) %>% mutate(AnyMes=as.Date(paste(Any,Numero,"1",sep="-"), "%Y-%m-%d")) %>% group_by(AnyMes, Mes, Delicte) %>% summarize(Coneguts = sum(Coneguts), Resolts = sum(Resolts), Detencions=sum(Detencions))

        # Pinta els homicidis consumats per dates
        # ggplot(denuncies_agrupades %>% filter(Delicte == "Homicidi consumat"), aes(x=AnyMes, y=Coneguts)) + geom_line() +  geom_smooth(method="lm")

        # Pinta els globals d'homicidis per dates
        resultat <- denuncies_agrupades %>% filter(grepl(elDelicte, Delicte)) %>% group_by(year(AnyMes)) %>% summarise(coneguts=sum(Coneguts), resolts=sum(Resolts))

    } else {
        zona <- args[2]

        # -----------------------------------
        denuncies_ae <- denuncies %>% filter(grepl(zona, ABP)) %>% select(Any, Numero, Mes, Delicte, Coneguts, Resolts, Detencions)  %>% mutate_if(is.numeric, funs(ifelse(is.na(.), 0, .))) %>% mutate(AnyMes=as.Date(paste(Any,Numero,"1",sep="-"), "%Y-%m-%d")) %>% group_by(AnyMes, Mes, Delicte) %>% summarize(Coneguts = sum(Coneguts), Resolts = sum(Resolts), Detencions=sum(Detencions))

        dades_ae <- denuncies_ae %>% filter(grepl(elDelicte, Delicte)) %>% group_by(year(AnyMes)) %>% summarise(coneguts=sum(Coneguts), resolts=sum(Resolts) )

        names(dades_ae) = c("Any", "coneguts", "resolts")

        # ggplot(dades_ae, aes(x=Any)) + geom_line(aes(y=coneguts), color="red") + geom_line(aes(y=resolts), color="green") + geom_smooth(aes(y=coneguts), method="lm") + geom_smooth(aes(y=resolts), method="lm")

        resultat <- dades_ae
    }
}

data.frame(resultat)