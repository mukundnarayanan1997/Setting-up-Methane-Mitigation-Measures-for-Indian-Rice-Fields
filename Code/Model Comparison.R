
library(e1071)
library(gbm)
library(randomForestSRC)
library(caTools)
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggthemes)
library(readr)

# Load the data
model_data <- read_csv("path/to/your/Mitigation Model Data.csv")
model_data <- model_data[-1]
split <- sample.split(model_data$`GWP20*10^8`, SplitRatio = 0.6)
training <- subset(model_data, split == TRUE)
testing <- subset(model_data, split == FALSE)

# Ensure that the columns are numeric
for (col in names(training)[1:4]) {
  training[[col]] <- as.numeric(as.character(training[[col]]))
  testing[[col]] <- as.numeric(as.character(testing[[col]]))
}

# Define a function for R-squared calculation
rsq <- function(y_act, y_pred) {
  ssr <- sum((y_act - y_pred)^2)
  sst <- sum((y_act - mean(y_act))^2)
  return(1 - ssr/sst)
}

# Train and predict with SVM
# Train SVM models for each output separately
svm_models <- lapply(names(training)[1:4], function(target) {
  svm(as.formula(paste("`", target, "` ~ .", sep = "")), data = training)
})

# Predict using SVM models
svm_predictions <- sapply(svm_models, function(model) predict(model, testing))
colnames(svm_predictions) <- names(training)[1:4]

# Train and predict with GTB
# Train GTB models for each output separately
gtb_models <- lapply(names(training)[1:4], function(target) {
  gbm(as.formula(paste("`", target, "` ~ .", sep = "")), data = training, distribution = "gaussian", n.trees = 100)
})

# Predict using GTB models
gtb_predictions <- sapply(gtb_models, function(model) predict(model, testing, n.trees = 100))
colnames(gtb_predictions) <- names(training)[1:4]

# Train and predict with RFSRC
# Train RFSRC model
modelRF <- rfsrc(Multivar(`Animal Manure (t)`, `Rice Residue (t)`, `N Fertilizer (t)`, `Water Input (km3)`) ~ ., data = training, ntree = 1000)

# Predict using RFSRC model
y_pred <- predict(modelRF, testing[-c(1:4)])
animal_pred <- y_pred[["regrOutput"]][["Animal Manure (t)"]]$predicted
residue_pred <- y_pred[["regrOutput"]][["Rice Residue (t)"]]$predicted
fertilizer_pred <- y_pred[["regrOutput"]][["N Fertilizer (t)"]]$predicted
WaterInput_pred <- y_pred[["regrOutput"]][["Water Input (km3)"]]$predicted
rfsrc_predictions <- as.data.frame(cbind(animal_pred, residue_pred, fertilizer_pred, WaterInput_pred))
colnames(rfsrc_predictions) <- c("Animal Manure (t)", "Rice Residue (t)", "N Fertilizer (t)", "Water Input (km3)")

# Evaluate and compare models
# Calculate R-squared for each model
calculate_rsq <- function(testing, predictions) {
  y_act = testing%>%
    pivot_longer(cols = 1:4, names_to = "Variables",values_to = "Observed")
  y_act['Index'] = 1:NROW(y_act)
  y_pred = predictions%>%
    pivot_longer(cols = 1:4, names_to = "Variables",values_to = "Predicted")
  y_pred['Index'] = 1:NROW(y_pred)
  r2_data = y_act%>%
    inner_join(y_pred, by = c("Index","Variables"))
  return(r2_data%>%
    group_by(Variables)%>%
    reframe(r2 = rsq(Observed,Predicted)))
}

svm_rsq <- calculate_rsq(testing[1:4], as.data.frame(svm_predictions))
gtb_rsq <- calculate_rsq(testing[1:4], as.data.frame(gtb_predictions))
rfsrc_rsq <- calculate_rsq(testing[1:4], as.data.frame(rfsrc_predictions))

# Combine R-squared results
rsq_results <- data.frame(
  Metric = c("Animal Manure (t)", "Rice Residue (t)", "N Fertilizer (t)", "Water Input (km3)"),
  SVM = svm_rsq['r2'],
  GTB = gtb_rsq['r2'],
  RFSRC = rfsrc_rsq['r2']
)
colnames(rsq_results) = c("Variable","SVM","GTB",'RF')
rsq_results%>%
  summarize()

# Plot predictions
# Combine observed and predicted values for plotting
y_act <- testing[1:4]
y_act$id <- 1:dim(y_act)[1]
y_act <- y_act %>%
  gather(key = "output", value = "Observed", -id)

# Create data frames for predicted values
svm_pred_df <- as.data.frame(svm_predictions)
svm_pred_df$id <- 1:dim(svm_pred_df)[1]
svm_pred_df <- svm_pred_df %>%
  gather(key = "output", value = "Predicted", -id)

gtb_pred_df <- as.data.frame(gtb_predictions)
gtb_pred_df$id <- 1:dim(gtb_pred_df)[1]
gtb_pred_df <- gtb_pred_df %>%
  gather(key = "output", value = "Predicted", -id)

rfsrc_pred_df <- as.data.frame(rfsrc_predictions)
rfsrc_pred_df$id <- 1:dim(rfsrc_pred_df)[1]
rfsrc_pred_df <- rfsrc_pred_df %>%
  gather(key = "output", value = "Predicted", -id)

# Combine all data frames for plotting
svm_full <- y_act %>% full_join(svm_pred_df, by = c("id", "output"))
gtb_full <- y_act %>% full_join(gtb_pred_df, by = c("id", "output"))
rfsrc_full <- y_act %>% full_join(rfsrc_pred_df, by = c("id", "output"))

# Plotting function
plot_predictions <- function(data, model_name) {
  ggplot(data) +
    geom_point(aes(x = Observed, y = Predicted, col = output), size = 0.5) +
    facet_wrap(~output, scale = "free") +
    ggtitle(paste("Predictions vs Observed for", model_name)) +
    theme_clean()
}

# Generate plots
plot_predictions(svm_full, "SVM")
plot_predictions(gtb_full, "GTB")
plot_predictions(rfsrc_full, "RFSRC")
