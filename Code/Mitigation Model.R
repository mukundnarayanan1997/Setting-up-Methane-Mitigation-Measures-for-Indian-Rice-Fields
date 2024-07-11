# Load necessary libraries
library(tidyverse)
library(caret)
library(readxl)
library(caTools)
library(randomForestSRC)
library(ggthemes)

# Function to read and split data
read_and_split_data <- function(file_path, split_ratio = 0.6) {
  model_data <- read_csv(file_path)
  split <- sample.split(model_data$`GWP20`, SplitRatio = split_ratio)
  training <- subset(model_data, split == TRUE)
  testing <- subset(model_data, split == FALSE)
  return(list(training = training, testing = testing))
}

# Function to train Random Forest model
train_rf_model <- function(training_data) {
  model <- rfsrc(Multivar(`Animal Manure (t)`, `Rice Residue (t)`, `N Fertilizer (t)`, `Water Input (km3)`) ~ .,
                 data = training_data, ntree = 1000)
  return(model)
}

# Function to compute variable importance
compute_variable_importance <- function(model) {
  v <- vimp(model, importance = "permute", csv = TRUE)
  csvimp <- get.mv.csvimp(v, standardize = TRUE)

  compute_importance <- function(imp_data) {
    imp <- as.data.frame(imp_data) %>%
      gather(key = "variables", value = "importance") %>%
      group_by(variables) %>%
      summarize(importance = mean(importance)) %>%
      mutate(importance2 = sum(importance)) %>%
      group_by(variables) %>%
      summarize(importance = importance / importance2)
    return(imp)
  }

  amimp <- compute_importance(csvimp$`Animal Manure (t)`)
  rsimp <- compute_importance(csvimp$`Rice Residue (t)`)
  nfimp <- compute_importance(csvimp$`N Fertilizer (t)`)
  wrimp <- compute_importance(csvimp$`Water Input (km3)`)

  csvimp <- full_join(amimp, rsimp, by = "variables") %>%
    full_join(nfimp, by = "variables") %>%
    full_join(wrimp, by = "variables")

  colnames(csvimp) <- c("Variables", "Animal Manure (t)", "Rice Residue (t)", "N Fertilizer (t)", "Water Input (km3)")
  csvimp[2:5] <- round(csvimp[2:5] * 100, 2)

  return(csvimp)
}

# Function to calculate R-squared value
rsq <- function(y_act, y_pred) {
  ssr <- sum((y_act - y_pred) ^ 2)
  sst <- sum((y_act - mean(y_act)) ^ 2)
  return(1 - ssr / sst)
}

# Function to test model accuracy
test_model_accuracy <- function(model, testing_data) {
  y_pred <- predict(model, testing_data[-c(1:4)])
  animal_pred <- y_pred[["regrOutput"]][["Animal Manure (t)"]]$predicted
  residue_pred <- y_pred[["regrOutput"]][["Rice Residue (t)"]]$predicted
  fertilizer_pred <- y_pred[["regrOutput"]][["N Fertilizer (t)"]]$predicted
  water_input_pred <- y_pred[["regrOutput"]][["Water Input (km3)"]]$predicted

  y_pred <- as.data.frame(cbind(animal_pred, residue_pred, fertilizer_pred, water_input_pred))
  colnames(y_pred) <- c("Animal Manure (t)", "Rice Residue (t)", "N Fertilizer (t)", "Water Input (km3)")

  test_results <- sapply(1:4, function(i) rsq(as.numeric(unlist(testing_data[i])), as.numeric(unlist(y_pred[i]))))
  names(test_results) <- c("Animal Manure (t)", "Rice Residue (t)", "N Fertilizer (t)", "Water Input (km3)")

  return(test_results)
}

# Function to plot observed vs predicted values
plot_observed_vs_predicted <- function(testing_data, y_pred) {
  y_act <- testing_data[1:4]
  y_act$id <- 1:nrow(y_act)
  y_act <- y_act %>%
    gather(key = "output", value = "Observed", -id)

  y_pred$id <- 1:nrow(y_pred)
  y_pred <- y_pred %>%
    gather(key = "output", value = "Predicted", -id)

  y_full <- full_join(y_act, y_pred)

  ggplot(y_full) +
    geom_point(aes(x = Observed, y = Predicted, col = output), size = 0) +
    facet_wrap(~output, scale = "free") +
    theme_clean()

  return(rsq(as.numeric(unlist(y_full)), as.numeric(unlist(y_full))))
}

# Main script
file_path <- "path/to/your/model_data.csv"  # Update with your generalized file path

data <- read_and_split_data(file_path)
model_rf <- train_rf_model(data$training)
variable_importance <- compute_variable_importance(model_rf)
testing_accuracy <- test_model_accuracy(model_rf, data$testing)

# Print the results
print(variable_importance)
print(testing_accuracy)

# Plot observed vs predicted values
plot_observed_vs_predicted(data$testing, testing_accuracy)
