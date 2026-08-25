/*==============================================================
1. Get existing indicator data
==============================================================*/

DROP TABLE IF EXISTS #indicators;

SELECT 
      a.[indicator_id],
      b.value_type,
      b.value_multiplier,
      b.indicator_polarity,
      b.circulatory_condition AS domain,
      a.[indicator_level_code] AS geography_code,
      a.[numerator],
      a.[denominator],

      CAST(
          CAST(a.numerator AS DECIMAL(18,6)) 
          / NULLIF(a.denominator, 0) 
          * b.value_multiplier 
          AS DECIMAL(18,6)
      ) AS indicator_value,

      TRIM(a.indicator_level) AS indicator_level

INTO #indicators

FROM [EAT_Reporting_BSOL].[Reporting].[BSOLBI_0328_Fact_Table] a

LEFT JOIN [EAT_Reporting_BSOL].[Reporting].[BSOLBI_0328_DIM_Indicators] b
    ON a.indicator_id = b.indicator_id

INNER JOIN [Cluster_BBCS].[BBCS].[Metric_Engine_Reference_Geography] c
    ON a.indicator_level_code = c.aggregation_code

WHERE demographic_split_one = 'All'
  AND demographic_split_two = 'All'
  AND TRIM(indicator_level) = 'GP Level'
  AND latest_date_flag = 1
  AND c.ICB_Split = 'BSOL';


/*==============================================================
2. Create total registered population for each BSOL GP
==============================================================*/

DROP TABLE IF EXISTS #gp_population;

SELECT
    a.GP_Code,
    COUNT(DISTINCT a.pseudo_nhs_number) AS denominator

INTO #gp_population

FROM [EAT_Reporting_BSOL].[Demographic].[BSOL_Registered_Population] a

INNER JOIN [Cluster_BBCS].[BBCS].[Metric_Engine_Reference_Geography] b
    ON a.GP_Code = b.aggregation_code

WHERE b.ICB_Split = 'BSOL'

GROUP BY
    a.GP_Code;


/*==============================================================
3. Update denominator for existing SUS indicator rows
==============================================================*/

UPDATE a
SET a.denominator = b.denominator

FROM #indicators a

INNER JOIN #gp_population b
    ON a.geography_code = b.GP_Code

WHERE a.indicator_id IN (1, 17, 18, 19);


/*==============================================================
4. ADD zero-event rows where GP has a denominator
   but no numerator/activity row
==============================================================*/

INSERT INTO #indicators
(
    indicator_id,
    value_type,
    value_multiplier,
    indicator_polarity,
    domain,
    geography_code,
    numerator,
    denominator,
    indicator_value,
    indicator_level
)

SELECT
    i.indicator_id,
    i.value_type,
    i.value_multiplier,
    i.indicator_polarity,
    i.circulatory_condition AS domain,

    gp.GP_Code AS geography_code,

    0 AS numerator,

    gp.denominator,

    CAST(0 AS DECIMAL(18,6)) AS indicator_value,

    'GP Level' AS indicator_level

FROM #gp_population gp

CROSS JOIN
(
    SELECT
        indicator_id,
        value_type,
        value_multiplier,
        indicator_polarity,
        circulatory_condition

    FROM [EAT_Reporting_BSOL].[Reporting].[BSOLBI_0328_DIM_Indicators]

    WHERE indicator_id IN (1, 17, 18, 19)

) i

WHERE NOT EXISTS
(
    SELECT 1

    FROM #indicators existing

    WHERE existing.geography_code = gp.GP_Code
      AND existing.indicator_id = i.indicator_id
);


/*==============================================================
5. Recalculate rates for ALL SUS indicators
==============================================================*/

UPDATE #indicators

SET indicator_value =
    CAST(numerator AS DECIMAL(18,6))
    / NULLIF(CAST(denominator AS DECIMAL(18,6)), 0)
    * 100000

WHERE indicator_id IN (1, 17, 18, 19);


SELECT * FROM #indicators