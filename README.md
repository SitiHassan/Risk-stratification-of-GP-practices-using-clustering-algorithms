# Risk Stratification of Practices Using Cardiovascular Indicators and Clustering Algorithms

## Overview

This work explores whether GP practices can be grouped according to their cardiovascular profiles using unsupervised machine learning techniques:

* K-means clustering
* Partitioning around medoids (PAM) clustering
* Hierarchical clustering

The original analytical request was to develop a heatmap comparing GP practices across a range of cardiovascular indicators. While this provides a useful view of individual indicators, it can be difficult to understand the overall cardiovascular profile of a practice when multiple indicators and clinical conditions are considered simultaneously.

This work therefore extends the original analysis by asking:

> **Can GP practices be grouped according to patterns of relative cardiovascular concern across multiple clinical domains?**

The longer-term aim is to provide commissioners with an additional analytical tool for identifying patterns of concern and prioritise practices for training or support.

The clustering is intended as an **exploratory prioritisation tool**, rather than a definitive classification of practice performance.

## Data

The analysis combines cardiovascular indicators from multiple datasets, including:

- Quality and Outcomes Framework (QOF)
- CVDPREVENT
- Secondary Uses Service (SUS)
- National Diabetes Audit (NDA)
- Prescribing data
- Mortality data
- Fingertips
- NHS Spine registered population data

Indicators are organised into seven cardiovascular domains:

1. Acute Coronary Syndrome (ACS)
2. Atrial Fibrillation (AF)
3. Cholesterol
4. Diabetes
5. Heart Failure
6. Hypertension
7. Stroke


## Methodology

The analysis follows the workflow:

**Data integration → Data quality assessment → Indicator standardisation → Domain composite scores → Exploratory analysis → PCA → Clustering → Cluster profiling**


### 1. Data Quality and Preparation

Data from the different sources are cleaned and integrated at GP practice level.

Data quality checks include:

- missing-value analysis;
- indicator completeness;
- numerator and denominator validation;
- identification of extreme values;
- investigation of denominator size;
- ensuring legitimate zero-event practices are retained.


### 2. Indicator Standardisation

Indicators have different units, distributions and interpretations. They are therefore standardised before being combined.

For indicator $j$ and practice $i$:

$$
z_{ij} = \frac{x_{ij} - \bar{x}_j}{s_j}
$$

where:

- $x_{ij}$ is the indicator value for practice $i$;
- $\bar{x}_j$ is the mean of indicator $j$ across practices;
- $s_j$ is the standard deviation of indicator $j$.


Indicator polarity is also aligned so that:

> **Higher standardised scores consistently represent greater relative concern.**


### 3. Domain Composite Scores

Standardised indicators belonging to the same cardiovascular domain are combined to produce a domain composite score.

For practice $i$ and domain $d$:

$$
D_{id} = \frac{1}{n_{id}}\sum_{j=1}^{n_{id}} z_{ij}
$$

where $n_{id}$ represents the number of eligible indicators contributing to the domain score.

The resulting domain composite scores are then standardised across practices:

$$
Z_{id} = \frac{D_{id} - \bar{D}_d}{s_{D_d}}
$$

where:

- $D_{id}$ is the composite score for practice $i$ in domain $d$;
- $\bar{D}_d$ is the mean domain composite score across practices;
- $s_{D_d}$ is the standard deviation of the domain composite score.

The resulting $Z_{id}$ is the final standardised domain score used in PCA and clustering.

The resulting domain scores therefore represent the **relative position of each practice compared with other practices** within each cardiovascular domain.


## Exploratory Data Analysis

Before clustering, the distributions and relationships between domain scores are investigated.

The analysis includes:

- histograms of domain scores;
- boxplots and outlier identification;
- investigation of denominator size and indicator values;
- correlation analysis;
- scatterplot matrices;
- Principal Component Analysis (PCA).

Some domains, particularly ACS and Stroke, show strongly right-skewed distributions and extreme observations.

Other domains, including Cholesterol and Hypertension, show substantially more symmetric distributions.


## Correlation Analysis

Pairwise correlations are examined to determine whether the cardiovascular domains contain distinct or highly overlapping information.

Most relationships are weak to moderate, suggesting that the domains capture different aspects of the cardiovascular profile.

A notable positive relationship is observed between Diabetes and Hypertension, with Cholesterol also contributing to a broader cardiometabolic pattern.


## Principal Component Analysis

PCA is used as an exploratory technique to investigate the dimensionality and underlying structure of GP cardiovascular profiles.

The first principal component explains approximately **27%** of total variance, while the first two components explain approximately **45%**.

Approximately **74%** of total variance requires four principal components.

The first component is particularly associated with Diabetes, Cholesterol and Hypertension, suggesting a broader cardiometabolic dimension.

However, practices do not form clearly separated groups in the first two principal components. The original seven standardised domain scores are therefore retained for clustering rather than reducing the analysis to PC1 and PC2.


## Cluster Analysis

Three clustering algorithms are compared:

### K-means

K-means partitions practices around cluster centroids by minimising within-cluster variation.

Multiple random initialisations are used to reduce sensitivity to starting centroid positions.

### Partitioning Around Medoids (PAM)

PAM is similar to K-means but represents clusters using actual observations (medoids) rather than calculated centroids.

This provides greater robustness to extreme observations.

### Hierarchical Clustering

Agglomerative hierarchical clustering is performed using Euclidean distance and Ward's minimum-variance method (`ward.D2`).

Ward's method progressively merges groups while minimising increases in within-cluster variation.


## Selecting the Number of Clusters

Solutions containing different numbers of clusters are compared using **average silhouette width**.

Silhouette width assesses both:

- cohesion within clusters; and
- separation between neighbouring clusters.

Among the solutions investigated, **K-means with four clusters provides the strongest comparative solution**, with an average silhouette width of approximately **0.18**.

However, this remains a relatively low silhouette value.

The results therefore suggest that GP cardiovascular profiles are **not characterised by strongly separated natural clusters** and may instead vary along a more continuous spectrum.


## Cluster Profiling

Following clustering, each cluster is profiled by calculating the mean standardised domain score among practices assigned to that cluster.

This allows the resulting groups to be interpreted according to their cardiovascular characteristics.

Across the clustering approaches, several recurring patterns are observed, including:

- small groups characterised by unusually high Stroke concern;
- small groups characterised by unusually high ACS concern;
- larger groups with relatively higher cardiometabolic concern;
- larger groups with relatively lower cardiometabolic concern.

The cardiometabolic profiles are primarily characterised by differences across:

- Cholesterol;
- Diabetes; and
- Hypertension.

Cluster numbers are arbitrary and are therefore interpreted according to their underlying domain profiles rather than their numerical labels.


## Sensitivity Analysis

Because several domain distributions contain skewness and extreme observations, cluster profiles are calculated using both **mean and median domain scores**.

Median profiling produces broadly similar cardiovascular patterns to mean profiling.

This provides additional evidence that the main cluster interpretations are not solely driven by a small number of extreme observations.


## Key Findings

The analysis provides evidence of some reproducible cardiovascular patterns across GP practices, particularly along a broader cardiometabolic dimension involving Diabetes, Cholesterol and Hypertension.

However, overall cluster separation is weak.

The findings therefore suggest that:

- practices vary across multiple cardiovascular dimensions;
- some recurring profiles can be identified;
- cardiovascular risk profiles appear to exist more along a continuum than as clearly separated groups;
- clustering can provide useful exploratory information but should not be used as a standalone classification of practice performance.

# Discussions

This approach provides an analytical layer beyond a traditional indicator-levle heatmap. Rather than only asking "Which practices have high concern for an individual indicator?", the analysis enables consideration of "Which practices show broader patterns of relative concern across multiple cardiovascular domains?". This could support commissioners
in understanding multidimensional patterns of cardiovascualr concern, targeting support or training, and prioritising resources.

The analysis has several limitations:
1- Different reporting periods
The analysis used the latest available indicators but these may represent different reporting periods due to differences in publication schedules and reporting lags. Therefore, this analysis can be extended across multiple time periods to assess the stability of practice profiles over time.

2- Rare-event measures
Some indicators such as admission-based rates in ACS and Stroke domains remain sensitive to practice population size, potentially producing unstable rates and extreme standardised scores. Next considerations would be to explore multi-year pooling or statistical smoothing methods.

3- Unequal domain representation
Domains contain different numbers of indicators, ranging from single-indicator domains to domains represented by several indicators. Reviewing and expanding indicator coverage particularly for under-represented domains where appropriate would be a good next step to improve the analysis.

4- Equal weighting
Indicators within domains are currently equally weighted, This is transparent and interpretable may not fully represent differences in clinical importance or statistical reliably. The next step would be to explore clinically informed or reliability-based weighting with subject-matter experts.

5- Population characteristics
The clustering doesn't incorporate the characteristics of the populations served by individual GP practices. This is a particularly important limitation because higher relative concern may reflect several factors, including:

* underlying population need
* demographic composition
* disease prevalence
* statistical variation
* practice population size

Therefore, it would be useful to incorporate measures such as age structure, deprivation, ethnicity, disease prevalence and other population-need characteristics to provide additional context.


## Conclusion

This work demonstrates how an initial reporting requirement can be extended into a broader exploratory analytical framework.

Rather than applying clustering simply because the technique is available, the analysis focuses on whether the resulting segmentation is statistically credible, interpretable and useful for the underlying business question.

The findings indicate that although some reproducible cardiovascular profiles can be identified, GP practices largely vary along a continuous multidimensional spectrum.

Most importantly, the resulting clusters should **not** be interpreted as definitive categories or good- or poor-performing GP pratices because higher relative concern may reflect several factors as outlined above. Cluster membership should therefore be considered alongside the underlying indicators, population characteristics and local intelligence when supporting commissioning decisions. 

The clustering should therefore be viewed as a tool to support **exploration, prioritisation and further investigation**, rather than as a definitive classification system.



This repository is dual licensed under the [Open Government v3]([https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/) & MIT. All code and outputs are subject to Crown Copyright.
