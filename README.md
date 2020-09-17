# Banking Insurance Product: Project Overview

A commercial bank wants to predict which customers will or will not purchase a variable annuity product.

### Part 1: Variable Understanding and Assumptions
* Explored relationship between individual predictor variables and target variable ("INS") with training data
* Used an alpha level of 0.002 to determine significant variables
* Determined odds ratios for binary predictor variables in relation to the target variable
* Tested linearity assumption for continuous predictor variables
* Made visual representation of missing variables

### Part 2: Variable Selection and Model Building
* Used newly binned training data and imputed missing values
* Checked each predictor variable for linear separation concerns
* Built a binary logistic regression model including only the main effects that predicted the purchase of the insurance product
  * Used backwards selection to do variable selection with an alpha level of 0.002
  * Obtained final variables ranked by significance
* Interpreted odds ratio from the main effects model
* Investigated potential interactions along with main effects using forward selection
* Reported final model to use in predicting the validation data

### Part 3: Model Assessment and Prediction
* Calculated probability metrics for the final model on training data
  * Percent Concordance
  * Discrimination Slope
* Calculated classification metrics for the final model on training data
  * ROC Curve
  * K-S Statistic
* Calculated classification metrics for the final model on validation data
  * Confusion Matrix
  * Accuracy Score
  * Lift Chart
