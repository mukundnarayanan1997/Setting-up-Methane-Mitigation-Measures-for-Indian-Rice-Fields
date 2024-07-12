# Setting up Methane Mitigation Measures for Indian Rice Fields: Representative Emissions and New Interpretations 
Fida Mohammad Sahil, Mukund Narayanan and Idhayachandhiran Ilampooranan*

Department of Water Resources Development and Management, Indian Institute of Technology Roorkee, Roorkee, Uttarakhand, India – 247667.

*Corresponding Author (Email: idhaya@wr.iitr.ac.in) 

This repository contains the code and datasets generated in this study. Please look at the corresponding folders to find the data and the code

# Data
### 1. District-Level Emission Factors Data.xlsx
This dataset contains emission factors at the district level under various water regimes, which include 
| Acronym      | Description                                                                                                            |
|--------------|------------------------------------------------------------------------------------------------------------------------|
| IR-CF        | Irrigated fields have standing water throughout the rice growing season and may only dry for harvest. Alternative names: Saturated fields, flooded fields, water retained through the season, etc. |
| IR-IF-SA     | Irrigated fields having a single aeration of more than three days during the cropping season at any growth stage.       |
| IR-IF-MA     | Irrigated fields having more than one aeration of more than three days period during the cropping season.               |
| RF-DP        | Rainfed rice fields with drought periods occur during every cropping season.                                            |
| RF-FP-DW     | Rainfed rice fields with the water level rising to 50 cm during the cropping season/to more than 50 cm for a significant period during the cropping season / Fields inundated with water depth from 50-100 cm / Fields inundated with water depth > 100 cm. |


### 2. Estimated Methane Emissions Data.xlsx
This is the final emissions data along with their uncertainties after monte carlo simulations

### 3. Literature Synthesis Data.xlsx
This dataset compiles findings from various studies on methane emissions in rice fields in India. A total of 68 field-scale experimental studies and two syntheses were selected from existing literature. This synthesis revealed that the rainfed-flood-prone and deep-water (RF-FP-DW) types have identical emissions in the Indian context; hence, these classes were grouped. The total data available for the synthesis resulted in 726 measurements across 43 locations in India. 

### 4. Mitigation Model Data.xlsx
This dataset includes model data used to simulate and evaluate the effectiveness of various methane mitigation measures. It contains variables such as animal manure, rice residue, N fertilizer, water input, rice yield, precipitation, temperature, soil organic carbon stock, and various global warming potential (GWP) and global temperature potential (GTP) metrics over different time horizons (20, 50, and 100 years).

# Code
### 1. Mitigation Model.R
This script focuses on building and analyzing a mitigation model for methane emissions in rice fields. The primary functions and operations in this script include:

- Library Imports: Loads necessary R libraries such as tidyverse, caret, readxl, caTools, randomForestSRC, and ggthemes.
- Data Reading and Splitting: Defines a function read_and_split_data to read data from a CSV file, split it into training and testing sets, and return these sets.
- Model Training: Defines a function train_rf_model to train a Random Forest model on the training data, predicting multiple variables such as animal manure, rice residue, nitrogen fertilizer, and water input.
- Variable Importance Calculation: Defines a function compute_variable_importance to compute the importance of different variables in the Random Forest model, standardize it, and aggregate results for various factors.
- R-squared Calculation: Defines a function rsq to calculate the R-squared value for model predictions against actual values, providing a measure of model accuracy.
- Plotting and Analysis: Generates plots to visualize the importance of different factors and their contributions to methane emissions.

### 2. Model Comparison.R
This script is designed to compare different models for predicting methane emissions and evaluate their performance. Key functions and operations include:

- Library Imports: Loads necessary R libraries such as tidyverse, caret, readxl, caTools, randomForestSRC, ggthemes, xlsx, and ggridges.
- Data Reading and Splitting: Similar to the Mitigation Model.R, it defines a function read_and_split_data to read and split the data.
- Model Training: Defines functions to train multiple models, including Random Forests and potentially other machine learning models.
- Scenario Data Generation: Defines a function generate_scenario_data to create different scenarios based on reductions in emission factors for a given year.
- Scenario Predictions: Defines a function predict_scenario to use the trained model to predict outcomes for different scenarios, including reductions in animal manure, rice residue, nitrogen fertilizer, and water input.
- Performance Evaluation: Evaluates the performance of different models by comparing their predictions against actual data, calculating metrics like R-squared, and visualizing results.

### 3. Scenarios Analysis.R
This script focuses on analyzing different scenarios to evaluate the impact of various mitigation strategies on methane emissions. Key functions and operations include:

- Library Imports: Loads necessary R libraries such as tidyverse, caret, readxl, caTools, randomForestSRC, ggthemes, xlsx, and ggridges.
- Data Reading and Splitting: Similar to the other scripts, it includes functions to read data from files and split it into training and testing sets.
- Scenario Data Generation: Defines a function generate_scenario_data to create data for different scenarios, adjusting emission factors based on specified reductions.
- Scenario Predictions: The trained model predicts outcomes for the generated scenarios, comparing different mitigation strategies' effectiveness.
- Visualization and Analysis: Generates plots to visualize the predicted outcomes for various scenarios, allowing for a detailed analysis of the potential impact of different mitigation measures.
