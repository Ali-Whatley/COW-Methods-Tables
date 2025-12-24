# -------------------------------------- # 
# Title: Examination of 
# Date: Dec. 23, 2025
# Name: Ali Whatley
# Data Used: 
# -------------------------------------- # 

rm(list = ls(all=T)) #clearing out your R session 

# Set your working directory 
setwd("~/Project/TVCI")
list.files()
# intall needed packages 
install.packages("pacman") # install pacman package to making loading packages easy
library(pacman) # load pacman into the session 
pacman::p_load(foreign, janitor, infer, stargazer, ggplot2, psych, dplyr, gt, tidyverse, skimr, readxl) # install and load all other packages into the session


#---------------------------------------------------------#
# ---- Data Loading ---- 
#---------------------------------------------------------#

#DV
mids <- read.csv("directed_dyadic_war.csv")

#IV
majors <- read.csv("majors2024.csv")
contiguity <- read.csv("contdird.csv")
nmc <- read.csv("NMC_5_0.csv")
cow_trade <- read_csv("Dyadic_COW_4.0.csv")
ally <- read.csv("alliance_v4.1_by_directed_yearly.csv")
gdp <- read_excel("PWT 110.xlsx")




#---------------------------------------------------------#
# ---- Data Information ---- 
#---------------------------------------------------------#







