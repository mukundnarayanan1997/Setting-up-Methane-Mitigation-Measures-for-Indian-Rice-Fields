# Load necessary libraries
library(tidyverse)
library(caret)
library(readxl)
library(caTools)
library(randomForestSRC)
library(ggthemes)
library(xlsx)
library(ggridges)

# Function to read and split data
read_and_split_data <- function(file_path, split_ratio = 0.6) {
  model_data <- read_csv(file_path)
  split <- sample.split(model_data$GWP20 * 10^8, SplitRatio = split_ratio)
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

# Function to generate scenario data
generate_scenario_data <- function(model_data, year, reduction) {
  scenario_data <- model_data %>%
    filter(Year == year)
  scenario_data[9:13] <- scenario_data[9:13] * 10^8
  colnames(scenario_data)[9:13] <- paste0(colnames(scenario_data)[9:13], "*10^8")
  scenario_data <- cbind(scenario_data[1:8], scenario_data[9:13] * (1 - reduction))
  return(scenario_data)
}

# Function to predict scenarios
predict_scenario <- function(model, scenario_data) {
  prediction <- predict(model, scenario_data)
  animal_pred <- prediction[["regrOutput"]][["Animal Manure (t)"]]$predicted
  residue_pred <- prediction[["regrOutput"]][["Rice Residue (t)"]]$predicted
  fertilizer_pred <- prediction[["regrOutput"]][["N Fertilizer (t)"]]$predicted
  water_input_pred <- prediction[["regrOutput"]][["Water Input (km3)"]]$predicted
  scenario_pred <- as.data.frame(cbind(animal_pred, residue_pred, fertilizer_pred, water_input_pred))
  colnames(scenario_pred) <- c("Animal Manure (t)", "Rice Residue (t)", "N Fertilizer (t)", "Water Input (km3)")
  scenario_merged <- cbind(scenario_data, scenario_pred)
  return(scenario_merged)
}

# Function to prepare scenario data for plotting
prepare_scenario_data_for_plot <- function(scenario_data, scenario_name) {
  scenario <- scenario_data %>%
    mutate(id = 1:nrow(scenario_data)) %>%
    gather(key = "Mitigation Measure", value = scenario_name, -id)
  return(scenario)
}

# Function to plot scenarios
plot_scenarios <- function(scenarios_predictions) {
  scenarios_predictions <- scenarios_predictions %>%
    mutate(`Mitigation Measure` = ifelse(`Mitigation Measure` == "Water Input (km3)", "Water Input (km^3)", `Mitigation Measure`))
  scenarios_predictions <- scenarios_predictions %>%
    gather(key = "Scenario", value = "Value", -c(id, `Mitigation Measure`))

  ggplot(scenarios_predictions) +
    geom_density_ridges(aes(x = Value, y = `Mitigation Measure`, fill = Scenario)) +
    theme_clean()
}

# Function to save data to Excel
save_data_to_excel <- function(data, file_path) {
  write.xlsx(data, file = file_path)
}

# Main script
file_path <- "path/to/your/Mitigation Model Data.csv"  # Update with your generalized file path
output_path <- "path/to/output/directory/Scenarios.xlsx"  # Update with your generalized output path

data <- read_and_split_data(file_path)
model_rf <- train_rf_model(data$training)

# Generate scenarios
scenarios <- list(
  `1.0` = generate_scenario_data(data$training, "2017", 0),
  `1.1` = generate_scenario_data(data$training, "2017", 0.25),
  `1.2` = generate_scenario_data(data$training, "2017", 0.5),
  `1.3` = generate_scenario_data(data$training, "2017", 0.75),
  `1.4` = generate_scenario_data(data$training, "2017", 1)
)

# Predict scenarios
scenario_predictions <- lapply(scenarios, function(scenario) predict_scenario(model_rf, scenario))

# Prepare data for plotting
scenario_data_list <- list()
for (i in names(scenario_predictions)) {
  scenario_data_list[[i]] <- prepare_scenario_data_for_plot(scenario_predictions[[i]], paste0("Scenario ", i))
}
scenarios_predictions <- reduce(scenario_data_list, full_join, by = c("id", "Mitigation Measure"))

# Plot scenarios
plot_scenarios(scenarios_predictions)

# Save data to Excel
save_data_to_excel(scenarios_predictions, output_path)

# Forward model
model_rf_forward <- rfsrc(Multivar(`GWP20*10^8`, `GWP100*10^8`, `GTP20*10^8`, `GTP50*10^8`, `GTP100*10^8`) ~ .,
                          data = data$training, ntree = 1000)

# Function to predict forward model
predict_forward_model <- function(model, scenario_merged) {
  prediction <- predict(model, scenario_merged[-c(9:13)])
  gwp20_pred <- prediction[["regrOutput"]][["GWP20*10^8"]]$predicted
  gwp100_pred <- prediction[["regrOutput"]][["GWP100*10^8"]]$predicted
  gtp20_pred <- prediction[["regrOutput"]][["GTP20*10^8"]]$predicted
  gtp50_pred <- prediction[["regrOutput"]][["GTP50*10^8"]]$predicted
  gtp100_pred <- prediction[["regrOutput"]][["GTP100*10^8"]]$predicted
  scen_pred <- cbind(gwp20_pred, gwp100_pred, gtp20_pred, gtp50_pred, gtp100_pred)
  colnames(scen_pred) <- paste0(c("GWP20_pred", "GWP100_pred", "GTP20_pred", "GTP50_pred", "GTP100_pred"), "_1.0")
  scenario_merged_pred <- as.data.frame(cbind(scenario_merged[-c(9:13)], scenario_merged[c(9:13)], scen_pred))
  return(scenario_merged_pred)
}

# Predict forward model for each scenario
scenario_merged_preds <- lapply(scenario_predictions, function(scenario) predict_forward_model(model_rf_forward, scenario))

# Compute R-squared
rsq <- function(y_act, y_pred) {
  ssr <- sum((y_act - y_pred)^2)
  sst <- sum((y_act - mean(y_act))^2)
  return(1 - ssr / sst)
}

# Example of computing R-squared for GWP20
rsq_data <- cbind(scenario_merged_preds[[1]]$`GWP20*10^8`, scenario_merged_preds[[1]]$GWP20_pred_1.0,
                  scenario_merged_preds[[2]]$`GWP20*10^8`, scenario_merged_preds[[2]]$GWP20_pred_1.1,
                  scenario_merged_preds[[3]]$`GWP20*10^8`, scenario_merged_preds[[3]]$GWP20_pred_1.2,
                  scenario_merged_preds[[4]]$`GWP20*10^8`, scenario_merged_preds[[4]]$GWP20_pred_1.3,
                  scenario_merged_preds[[5]]$`GWP20*10^8`, scenario_merged_preds[[5]]$GWP20_pred_1.4)
rsq_results <- apply(rsq_data, 1, function(row) rsq(row[seq(1, length(row), 2)], row[seq(2, length(row), 2)]))

# Print R-squared results
print(rsq_results)
