#' ---
#' title: "Starbucks Locations"
#' author: "A. Lewis & Z. Liu"
#' date: "4/23/2019"
#' output: html_document
#' ---
#' 
## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(gstat)
library(sp)
library(sf)
library(spatstat)
library(ggplot2)
library(maps)
library(spdep)
library(shapefiles)
library(maptools)
library(splines)
library(spgwr)      
library(GWmodel)  
library(RColorBrewer) 
library(classInt) 

#' 
#' 
#' In the first section, we load the data and create four maps. The first two are maps of starbucks locations in california and the world respectively. The last two are the same data, but with a background map that shows state/country boundaries.
## ------------------------------------------------------------------------

## Load Data
sb <- read.csv("/Users/tennyliu/Desktop/MATH161/Z Project/directory.csv") ### CHANGE THIS AS NECESSARY
sb <- sb[!is.na(sb$Longitude),]

#Convert to spatial
coordinates(sb) <- ~Longitude+Latitude

#Separate data for California
cali <- sb[sb$State.Province == "CA",]

#Map distribution of starbucks in California
spplot(cali, zcol = "Brand")

#Plot Starbucks worldwide
spplot(sb, zcol = "Brand")

#Load world map so we can plot on top of that
WorldData <- map_data('world')
WorldData <- fortify(WorldData)

#Change starbucks locations dataset back to df
sb.df <- as.data.frame(sb)

#Plot starbucks locations on a world map
p <- ggplot()
p <- p + geom_map(data=WorldData, map=WorldData,
         aes(group=group, map_id=region),
         fill="white", colour="#7f7f7f", size=0.5)
p <- p + geom_point(data=sb.df, aes(x = Longitude, y = Latitude))
p

# Load data for a California map
usa <- map_data("state")
caliMap <- subset(usa, region = "California")
cali.df <- as.data.frame(cali)

#Plot locations in California with a background map of the state
q <- ggplot()
q <- q + geom_map(data=caliMap, map=caliMap,
         aes(group=group, map_id=region),
         fill="white", colour="#7f7f7f", size=0.5)
q <- q + geom_point(data=cali.df, aes(x = Longitude, y = Latitude))
q

#' 
#' 
#' In this section, we take in data from the census api and make three figures that overlay a given aspect of census data with starbucks locations. My first graph is a graph of median county-level income in the US, then we subset this to California, and finally we do the number of white population in counties in California. If we want to incorporate the final graph or any other metrics related to race, we should probably divide by the total population in the census tract. 
## ------------------------------------------------------------------------
#First, set up the census api
library(tidycensus) #Load tidycensus to be able to draw in census data
Sys.setenv(CENSUS_KEY="a83c5996031ce19af8a1cee6676bfd8af7f251f9") # This might be redundant with the line below
#census_api_key("a83c5996031ce19af8a1cee6676bfd8af7f251f9", install = TRUE) #You may need to get your own key
readRenviron("~/.Renviron") # I think you need to do this to get the api key working




## How do starbucks locations compare to median county-level income in the US?

#Load median income for every county in the US
us_county_income <- get_acs(geography = "county", variables = "B19013_001", 
                            shift_geo = TRUE, geometry = TRUE)

cty.sp <- as(us_county_income, "Spatial")
#Subset starbucks locations to only have locations in the US
sb_us <- sb[sb$Country == "US",]
#Plot median incomes overlaid with starbucks locations
spplot(cty.sp, zcol = "estimate", 
       sp.layout = list(cty.sp, col = "green"))




## How do starbucks locations compare to median county-level income within California?

#Get income data for the state of California
cali_county_income <- get_acs(geography = "county", variables = "B19013_001",year = 2017, 
                              geometry = TRUE, state = "California")
cali.sp <- as(cali_county_income, "Spatial") #Convert to spatial polygons
#Plot median incomes overlaid with starbucks locations
spplot(cali.sp, zcol = "estimate", 
       sp.layout = list(cali, col = "green", cex = 0.1, pch = 1))



# How do starbucks locations compare to the number of white population in a census tract in California?

#Get data for the number of white
cali_county_white <- get_acs(geography = "county", variables = "B02008_001", year = 2017,
                              geometry = TRUE, state = "California")
cali.white.sp <- as(cali_county_white, "Spatial")#Convert to spatial polygons
# Plot the number of white people overlaid with starbucks locations
spplot(cali.white.sp, zcol = "estimate", 
       sp.layout = list(cali, col = "green", cex = 0.1, pch = 1))

#add the number of starbucks in each county to data
cali.sp$n.sb <- n.sb.cali
#add white population to data
cali.sp$White_Population <- cali.white.sp$estimate


#total population
cali_pop <- get_acs(geography = "county", variables = "B01003_001E", year= 2017,
                              geometry = TRUE, state = "California")
cali.pop.sp <-as(cali_pop, "Spatial")

#young peeps
cali_median_age <- get_acs(geography = "county", variables = "B01002_001E", year = 2017,
                              geometry = TRUE, state = "California")
cali.median.age.sp <-as(cali_median_age, "Spatial")
cali.sp$Median_Age <- cali.median.age.sp$estimate


#median house value 2010 and later
cali_median_house_2015 <- get_acs(geography = "county", variables = "B25109_002E", year = 2017,
                              geometry = TRUE, state = "California")
cali.median.house.15.sp <-as(cali_median_house_2015, "Spatial")

cali_median_house_2010 <- get_acs(geography = "county", variables = "B25109_003E", year = 2017,
                              geometry = TRUE, state = "California")
cali.median.house.10.sp <-as(cali_median_house_2010, "Spatial")

cali.sp$Median_House_Value<- (cali.median.house.15.sp$estimate + cali.median.house.10.sp$estimate )/2


cali.sp$Total_Population<- cali.pop.sp@data$estimate
cali.pop.sp$n.sb.per.capita <- cali.sp$n.sb/cali.sp$Total_Population *1000
cali.white.sp$n.sb.per.white <- cali.sp$n.sb/cali.sp$White_Population *1000
cali.sp$white.percentage <- cali.sp$White_Population/cali.sp$Total_Population 
spplot(cali.pop.sp, zcol ="n.sb.per.capita" )
spplot(cali.white.sp, zcol = "n.sb.per.white")
spplot(cali.sp, zcol = "Total_Population",  sp.layout = list(cali, col = "green", cex = 0.1, pch = 1))
spplot(cali.sp, zcol = "white.percentage", sp.layout = list(cali, col = "green", cex = 0.1, pch = 1))
spplot(cali.sp, zcol = "Median_Age", sp.layout = list(cali, col = "green", cex = 0.1, pch = 1), main = "California County Median Age")
spplot(cali.sp, zcol = "Median_House_Value",  sp.layout = list(cali, col = "green", cex = 0.1, pch = 1))

# To find the variable code for other variables that you're interested in (e.g."B19013_001" for median income) you can use this website:
    ## https://api.census.gov/data/2015/acs/acs5/variables.html


#' 
#' 
#' In this section, I compute the density of starbucks within each census tract. We can then use this as a variable for other analyses. All I do is plot it right now.
## ------------------------------------------------------------------------
library(GISTools)
n.sb.cali = poly.counts(cali,cali.sp) #Counts the number of starbucks locations within each county of California
choropleth(cali.sp,n.sb.cali/poly.areas(cali.sp)) #Maps the number of starbucks/area of the county
#(this returns an error message and I'm not sure why. The graph should still work)

#add the number of starbucks in each county to median income data
cali.sp$n.sb <- n.sb.cali
cali.sp$White_Population <- cali.white.sp$estimate
#univariate spatial correlation of starbucks distribution: moran's I
sb.neighbors <-poly2nb(cali.sp,queen=TRUE)
W.nb<- nb2listw(sb.neighbors, style="W", zero.policy = TRUE)
moran.test(cali.sp@data$n.sb,W.nb, zero.policy = TRUE)
spplot(cali.sp, zcol="n.sb")

#linear model: number of starbucks ~ median household income
colnames(cali.sp@data)[4]<- "Median_Income"
#normalizing median household income
hist(cali.sp@data$n.sb)
cali.sp$logged_n.sb<- log(cali.sp@data$n.sb +1)
hist(cali.sp$logged_n.sb)
lm1<- lm(cali.sp$n.sb ~ cali.sp$Median_Income)
res1<- residuals(lm1)
plot(res1)
cali.sp$lm1_res <- res1
#plot residuals
spplot(cali.sp, zcol = "lm1_res")
moran.test(cali.sp@data$lm1_res,W.nb, zero.policy = TRUE)

#linear model with median income, white population, total population and median age
lm2<- lm(cali.sp$logged_n.sb ~ cali.sp$Median_Income + cali.sp$White_Population  + cali.sp$Median_Age+ cali.sp$Median_House_Value, na.action = na.exclude)
lm2
res2<- residuals(lm2)
cali.sp$lm2_res<- res2
spplot(cali.sp, zcol="lm2_res")
moran.test(cali.sp@data$lm2_res,W.nb, zero.policy = TRUE, na.action = na.exclude)

lm3<- lm(cali.sp$logged_n.sb ~ cali.sp$Median_Income + cali.sp$white.percentage + cali.sp$Median_Age + cali.sp$Median_House_Value, na.action = na.exclude)
res3<- residuals(lm3)
cali.sp$lm3_res <- res3
spplot(cali.sp, zcol="lm3_res")
moran.test(cali.sp@data$lm3_res,W.nb, zero.policy = TRUE, na.action = na.exclude)


#GWR
cali.sp.na.omit<- cali.sp[-c(2,8),]
bwG<- gwr.sel(cali.sp.na.omit$logged_n.sb ~ cali.sp.na.omit$Median_Income + cali.sp.na.omit$White_Population +cali.sp.na.omit$Total_Population + cali.sp.na.omit$Median_Age + cali.sp.na.omit$Median_House_Value, gweight=gwr.Gauss, data=cali.sp, verbose=T)

model.gwr <- gwr.basic(cali.sp.na.omit$logged_n.sb ~ cali.sp.na.omit$Median_Income + cali.sp.na.omit$White_Population +cali.sp.na.omit$Total_Population + cali.sp.na.omit$Median_Age + cali.sp.na.omit$Median_House_Value, data=cali.sp.na.omit, bw=bwG, kernel='gaussian')
model.gwr
cali.sp.na.omit$res_gwr <- model.gwr$SDF$residual
spplot(cali.sp.na.omit, zcol="res_gwr")

classes_fx <- classIntervals(res, n=5, style="fixed", fixedBreaks=c(-1.5,-0.75,0,0.75,1.5), rtimes = 1)
res.palette <- colorRampPalette(c("blue","purple","pink", "orange","yellow"), space = "rgb")
pal <- res.palette(5)
cols <- findColours(classes_fx,pal)

par(mar=rep(0,4))
plot(cali.sp,col=cols, border="grey")
legend(x="bottom",cex=1,fill=attr(cols,"palette"),bty="n",legend=names(attr(cols, "table")),ncol=5)

sb.na.omit.neighbors <-poly2nb(cali.sp.na.omit,queen=TRUE)
W.nb.na.omit<- nb2listw(sb.na.omit.neighbors, style="W", zero.policy = TRUE)
moran.test(res, listw=W.nb.na.omit, zero.policy=T)

#CAR SAR moddels
sar.out<- spautolm(logged_n.sb ~ cali.sp$Median_Income + cali.sp$White_Population + cali.sp$Total_Population + cali.sp$Median_Age + cali.sp$Median_House_Value, data=cali.sp, family="SAR", listw=W.nb, zero.policy = TRUE)
summary(sar.out)
#sar.out<- spautolm(logged_n.sb ~ cali.sp$Median_Income + cali.sp$White_Population +cali.sp$Total_Population, data=cali.sp, family="SAR", listw=W.nb, zero.policy = TRUE)

car.out<- spautolm(logged_n.sb ~ cali.sp$Median_Income + cali.sp$White_Population +cali.sp$Total_Population + cali.sp$Median_Age + cali.sp$Median_House_Value, data=cali.sp, family="CAR", listw=W.nb, zero.policy = TRUE)

#car.out<- spautolm(logged_n.sb ~ cali.sp$Median_Income + cali.sp$white.percentage+, data=cali.sp, family="CAR", listw=W.nb, zero.policy = TRUE)
summary(car.out)


#' 
#' In this section, we load census data for Wisconsin and use the previous linear model to predict county-wide Starbucks abundance.
## ------------------------------------------------------------------------
#Separate data for Wisconsin
wi <- sb[sb$State.Province == "WI",]

#Get income data for the state of Wisconsin
wi_county_income <- get_acs(geography = "county", year = 2017, variables = "B19013_001", 
                              geometry = TRUE, state = "Wisconsin")
wi.sp <- as(wi_county_income, "Spatial") #Convert to spatial polygons
#Plot median incomes overlaid with starbucks locations
spplot(wi.sp, zcol = "Median_Income", 
       sp.layout = list(wi, col = "green", cex = 0.1, pch = 1))

#Get data for the number of white people in Wisconsin
wi_county_white <- get_acs(geography = "county", year = 2017, variables = "B02008_001", 
                              geometry = TRUE, state = "Wisconsin")
wi.white.sp <- as(wi_county_white, "Spatial")#Convert to spatial polygons
# Plot the number of white people overlaid with starbucks locations
spplot(wi.white.sp, zcol = "estimate", 
       sp.layout = list(wi, col = "green", cex = 0.1, pch = 1))
wi.sp$White_Population<- wi.white.sp@data$estimate

#Get data for the median age in Wisconsin
wi_county_age <- get_acs(geography = "county", year = 2017, variables = "B01002_001E", 
                              geometry = TRUE, state = "Wisconsin")
wi.age.sp <- as(wi_county_age, "Spatial")#Convert to spatial polygons
# Plot the number of white people overlaid with starbucks locations
spplot(wi.age.sp, zcol = "estimate", 
       sp.layout = list(wi, col = "green", cex = 0.1, pch = 1))
wi.sp$Median_Age<- wi.age.sp@data$estimate
colnames(wi.sp@data)[4]<- "Median_Income"

#total population
wi_pop <- get_acs(geography = "county", year = 2017, variables = "B01003_001E", 
                              geometry = TRUE, state = "Wisconsin")
wi.pop.sp <-as(wi_pop, "Spatial")
# Plot the number of white people overlaid with starbucks locations
spplot(wi.pop.sp, zcol = "estimate", 
       sp.layout = list(wi, col = "green", cex = 0.1, pch = 1))
wi.sp$Total_Population<- wi.pop.sp@data$estimate
wi.sp$White_Pct<- wi.white.sp@data$estimate/wi.sp$Total_Population

#median house value 2010 and later
wi_median_house_2015 <- get_acs(geography = "county", variables = "B25109_002E", 
                                  year = 2017, geometry = TRUE, state = "Wisconsin")
wi.median.house.15.sp <-as(wi_median_house_2015, "Spatial")
wi_median_house_2010 <- get_acs(geography = "county", variables = "B25109_003E", 
                                  year = 2017, geometry = TRUE, state = "Wisconsin")
wi.median.house.10.sp <-as(wi_median_house_2010, "Spatial")
wi.sp$Median_House_Value<- (wi.median.house.15.sp$estimate + wi.median.house.10.sp$estimate )/2

spplot(wi.sp, zcol = "White_Pct", 
       sp.layout = list(wi, col = "green", cex = 0.1, pch = 1))

n.sb.wi = poly.counts(wi,wi.sp) #Counts the number of starbucks locations within each county of WI
choropleth(wi.sp,n.sb.wi/poly.areas(wi.sp)) #Maps the number of starbucks/area of the county
#(this returns an error message and I'm not sure why. The graph should still work)

#add the number of starbucks in each county to median income data
wi.sp$n.sb <- n.sb.wi
wi.sp$logged_n.sb <- log(wi.sp$n.sb+1) #log-transform

#What happens if you make a model for Wisconsin?
lm10 <- lm(wi.sp$logged_n.sb~wi.sp$White_Population++wi.sp$Median_Income+wi.sp$Median_Age+wi.sp$Median_House_Value)
summary(lm10)
pred <- predict(lm10)
plot(pred,wi.sp$logged_n.sb)


#Predict using California model
pred <- predict(lm2, wi.sp)
wi.sp$Pred <- pred
wi.sp$Untransformed_pred <- exp(wi.sp$Pred) #Backtransform so that these are in absolute rather than logged values
wi.sp$Dif <- wi.sp$Untransformed_pred-wi.sp$n.sb #Calculate residuals


spplot(wi.sp, zcol="Pred")
spplot(wi.sp, zcol="logged_n.sb")
spplot(wi.sp, zcol="n.sb", at = c(seq(0,max(wi.sp$n.sb+2),.5)))
spplot(wi.sp, zcol="Untransformed_pred", at = c(seq(0,max(wi.sp$n.sb+2),.5)))
spplot(wi.sp, zcol="Dif")

#Moran's I
wi.neighbors <-poly2nb(wi.sp,queen=TRUE)
W.nb.wi<- nb2listw(wi.neighbors, style="W", zero.policy = TRUE)
moran.test(wi.sp@data$Dif,W.nb.wi, zero.policy = TRUE)

