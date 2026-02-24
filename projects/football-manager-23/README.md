# Football Manager 2023 Analysis

---

## Problem Statement

Every Football Manager player faces the same challenge: too many players, too little budget, and too little time to scout everyone manually. 
The game rewards managers who can identify undervalued talent, spot the next wonderkid before their price spikes, and build balanced squads 
without overspending.

This project uses data analysis to answer the questions that actually matter at the transfer table — turning thousands of rows of player 
attributes into clear, actionable scouting intelligence.

**Who benefits from this?**
- FM players who want a competitive edge in recruitment
- Gamers who want to build a competitive squad on a tight budget
- Anyone who wants to understand what the game's engine actually rewards

---

## Objectives

- Identify young players (under 21) with the highest growth potential relative to their current ability
- Surface the most undervalued players by position: high attributes, low transfer fee
- Determine which attribute combinations define elite players at each position
- Discover which nationalities and leagues produce the most technically gifted and most affordable talent
- Build an optimized "budget dream team" by maximizing key attributes per dollar spent under a fixed transfer budget

---

## Dataset

**Source:** Kaggle

```
import kagglehub

# Download latest version
path = kagglehub.dataset_download("siddhrajthakor/football-manager-2023-dataset")

print("Path to dataset files:", path)
```

---

## Data Preparation

The raw dataset required several cleaning steps before analysis. Missing or placeholder values (denoted as `-`) were present across performance 
columns like injury records and appearance stats; these were either imputed with median values where appropriate or excluded from specific analyses. 
Duplicate player records were removed using the UID field.

Transfer values were stored as strings with currency symbols and were converted to numeric format to enable modeling and comparison. Age was derived 
from the Date of Birth column to allow consistent filtering and cohort segmentation. A value efficiency score was engineered for each player by 
dividing a composite attribute score by transfer fee, enabling the undervalued player analysis. Position labels were standardized to broader 
groupings (e.g., AM, DM, GK, CB, ST) to allow like-for-like comparisons across roles.

---

## Methodology

**Exploratory Data Analysis** was conducted first to understand attribute distributions by position, age, and league, and to identify any data 
quality issues worth addressing before modeling.

For the **wonderkid analysis**, players aged 21 and under were filtered and ranked using a composite score weighted toward technical and 
mental development attributes (Technique, Determination, and Natural Fitness) which the FM engine favors for growth.

The **undervalued player analysis** used a value efficiency ratio combining a weighted attribute composite (tailored per position) against 
transfer fee, highlighting players in the bottom quartile of price but the top quartile of relevant stats.

**Attribute profiling by position** was done using mean comparison and correlation analysis across position groups to identify which skills 
statistically separate elite players (top 10% transfer value) from the rest.

**League and nationality scouting** used aggregated attribute scores grouped by nation and division, filtered for affordability, to surface 
the best hunting grounds for cheap, high-quality talent.

The **budget dream team** was built as a constrained optimization problem — maximizing a squad-level composite score across 11 positions 
under a fixed transfer budget, using a greedy selection approach.

All models were evaluated using interpretability as the primary criterion, since the goal is actionable scouting output rather than predictive accuracy.

---

## Tools and Technologies

- Python 3.11
- Pandas and NumPy — data cleaning, feature engineering, aggregation
- Scikit-learn — clustering, optimisation
- Matplotlib, Seaborn and Plotly — visualization and dashboards
- Jupyter Notebook — primary analysis environment

---

# Notes

This project is a deliberate attempt to close the gap between *doing analysis* and *communicating findings to a real audience*. The gamer 
framing forced concrete, specific questions rather than open-ended exploration.

**What I'd improve next:** incorporating a time-series element by comparing FM editions year-on-year to see how attribute inflation 
affects value, and building an interactive Streamlit app for the scouting tool so non-technical users can explore results directly.

**Possible extensions:** predicting player regression risk by age and position; building a save-file specific recommendation engine 
that scouts for your exact formation and budget.