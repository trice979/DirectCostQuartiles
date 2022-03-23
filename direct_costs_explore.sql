WITH			DRGCounts AS (
SELECT			enc.MSDRG ,
				svc.[MS-DRG Description] ,
				svc.[MS-DRG-Service Line Group] ,
				svc.[MS-DRG-Based Service Line] ,
				svc.[MS-DRG-Based Sub Service Line]  ,
				COUNT(DISTINCT enc.PatientAccount) Discharges ,
				AVG(enc.TotalDirectCosts) AverageDirectCosts ,
				AVG(enc.TotalActualPayment) AveragePayments
FROM			  T_IP_ENCOUNTER enc
LEFT JOIN		Analytics.SG2.[MT - SVC Line to MS-DRG 2019] svc
					    on enc.MSDRG = svc.[MS-DRG v36]
WHERE			enc.DischargeDate BETWEEN '2019-01-01' AND '2019-10-31'
AND				enc.UserField4 in ('4' , '50')		
AND				enc.FacilityID = 1
AND				enc.TotalCharges > 0
AND				enc.TotalDirectCosts > 0
GROUP BY		enc.MSDRG ,
				svc.[MS-DRG Description] ,
				svc.[MS-DRG-Service Line Group] ,
				svc.[MS-DRG-Based Service Line] ,
				svc.[MS-DRG-Based Sub Service Line]  )

SELECT			DISTINCT
				DRGCounts.[MS-DRG-Service Line Group] ,
				DRGCounts.[MS-DRG-Based Service Line] ,
				DRGCounts.[MS-DRG-Based Sub Service Line]  ,
				enc.MSDRG ,
				DRGCounts.[MS-DRG Description] DRGDesc,
				DRGCounts.Discharges ,
				DRGCounts.AverageDirectCosts ,
				DRGCounts.AveragePayments ,
				PERCENTILE_DISC(0) WITHIN GROUP (ORDER BY enc.TotalDirectCosts) OVER (PARTITION BY enc.MSDRG) Minimum ,
				PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY enc.TotalDirectCosts) OVER (PARTITION BY enc.MSDRG) Q1,
				PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY enc.TotalDirectCosts) OVER (PARTITION BY enc.MSDRG) Median,
				PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY enc.TotalDirectCosts) OVER (PARTITION BY enc.MSDRG) Q3,
				PERCENTILE_DISC(1) WITHIN GROUP (ORDER BY enc.TotalDirectCosts) OVER (PARTITION BY enc.MSDRG) Maximum ,
				CAST(STDEV(enc.TotalDirectCosts) OVER (PARTITION BY enc.MSDRG) AS DECIMAL(10,2)) StandardDeviation 
				
FROM			UMMC_SYSTEM..T_IP_ENCOUNTER enc
INNER JOIN		DSS..DATE dt
					on enc.DischargeDate = dt.date
LEFT JOIN		DRGCounts
					on enc.MSDRG = DRGCounts.MSDRG
WHERE			enc.DischargeDate BETWEEN '2019-01-01' AND '2019-10-31'
AND				enc.UserField4 in ('4' , '50')		
AND				enc.FacilityID = 1
AND				enc.TotalCharges != 0
AND				enc.TotalDirectCosts > 0
AND				DRGCounts.[MS-DRG-Service Line Group] is not null

GROUP BY		DRGCounts.[MS-DRG-Service Line Group] ,
				DRGCounts.[MS-DRG-Based Service Line] ,
				DRGCounts.[MS-DRG-Based Sub Service Line]  ,
				enc.MSDRG ,
				DRGCounts.AverageDirectCosts ,
				DRGCounts.AveragePayments ,
				enc.TotalDirectCosts,
				DRGCounts.Discharges ,
				DRGCounts.[MS-DRG Description] 

ORDER BY		enc.MSDRG
