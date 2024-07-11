#zonal stats
library(raster)
library(rgdal)
library(tidyverse) 
library(xlsx)
#yearly
setwd(r"(G:\My Drive\fida paper 2\Fida Paper 2 JESS\Mitigation Model\Rice Residue\Rasters)")
datafiles = Sys.glob("*.tif")
s = stack()
for(i in datafiles){
  temp = raster(i)
  s = stack(s,temp)
}

poly = shapefile(r"(G:\My Drive\fida paper 2\Fida Paper 2 JESS\1971_2016 districts aligned\shapefile\dist2016.shp)")

df = raster::extract(s, poly, fun='mean', na.rm=TRUE, df=TRUE, weights = TRUE)
df = poly@data%>%
  mutate(ID = 1:(dim(poly@data)[1]))%>%
  full_join(df)
full= read_xlsx(r"(G:\My Drive\fida paper 2\Fida Paper 2 JESS\1971_2016 districts aligned\GROUPED DISTRICTS 2016.xlsx)",
                sheet = 2)
full = full%>%
  inner_join(df, by= "Grouped")
full$Units = "t"
write.xlsx(full,r"(G:\My Drive\fida paper 2\Fida Paper 2 JESS\Mitigation Model\Rice Residue\rice_residue_zonal.xlsx)")


