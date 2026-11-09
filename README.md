# Predicting 30-Day Hospital Readmission

An Advanced Topics in AI course project at Wrocław University of Science and Technology.

## Research question

How well can machine learning models predict whether a hospital encounter for a patient with diabetes will be followed by a readmission within 30 days? Which features do the models rely on most?

## Dataset

This project uses the [Diabetes 130-US Hospitals dataset](https://archive.ics.uci.edu/dataset/296/diabetes+130-us+hospitals+for+years+1999-2008). Download the dataset and place `diabetic_data.csv` and `IDS_mapping.csv` in the `data/` folder.

## Experiment 1

I compared logistic regression, random forest, and gradient boosting using five-fold cross-validation repeated 20 times. I grouped encounters by patient so that the same patient could not appear in both training and testing within a fold.

- [Project notebook](data/00_exploration.ipynb)
- [ROC-AUC results table](data/experiment1/summary_auc.csv)
- [ROC-AUC boxplot](data/experiment1/auc_boxplot.png)
- [Calibration curve](data/experiment1/calibration_curve.png)