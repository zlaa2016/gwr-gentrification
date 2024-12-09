# Starbucks Locations & Gentrification via Geographically Informed Models
 
Code & Figures for Starbucks Locations & Gentrification project 

*Overview*

---

Gentrification, or the movement of affluent residents and businesses into diverse,
low-income urban areas, is known to cause shortages of affordable housing, health
consequences, and cultural displacement. In this study, we examine the geographical distribution
of Starbucks, an upper-middle-class aesthetic landmark, to determine its association with
gentrification-related demographic factors. We find that a linear model relating county-wide
starbucks abundance to median age, white population, median income, and median household
value captures most of the spatial variation in Starbucks abundance within the state of California
and performs comparably to several types of spatially-informed models (SAR, CAR, GWR). We
then used our linear model to predict another state with a drastically different population,
Wisconsin, and found mixed results. There was no spatial autocorrelation in the residual error in
Wisconsin, indicating that we adequately captured much of the spatial variability in Starbucks
locations. However, the model almost universally overestimated the number of Starbucks in
counties in Wisconsin and severely underestimated one major city. While gentrification-related
demographic factors can be used to explain trends in the spatial distribution of Starbucks density,
other regional factors likely modulate these trends on a national scale.



*Methods include:*

---

* Linear Regression  
* Geographically Weighted Regression (GWR)  
* Simultaneous Autoregression (SAR)
* Conditional Autoregression (CAR) 
* Hypothesis testing for spatial randomness    


*Below are some of the visualizations used in the exploratory analysis and model evaluations:*

Starbucks locations worldwide:
![Figure of starbucks location worldwide](https://github.com/zlaa2016/Geo-weighted-Regression_Gentrification/blob/master/figures/locations_world.png)  
Starbucks locaions against median household income by county in California:
![Figure of starbucks location cali](https://github.com/zlaa2016/Geo-weighted-Regression_Gentrification/blob/master/figures/locations_cali.png)   
Starbucks number Actual(left) vs. Predicted(right): 
![Figure of results](https://github.com/zlaa2016/Geo-weighted-Regression_Gentrification/blob/master/figures/prediction.png) 

