
-- Ringkasan KPI pelanggan untuk dashboard RFM
WITH tanggal_acuan AS (
    SELECT MAX(DATE(created_at)) AS tanggal_terakhir_data
    FROM `bigquery-public-data.thelook_ecommerce.order_items`
),
rfm AS (
    SELECT
        oi.user_id,
        DATE_DIFF(
            (SELECT tanggal_terakhir_data FROM tanggal_acuan),
            MAX(DATE(oi.created_at)),
            DAY
        ) AS recency_hari,
        COUNT(DISTINCT oi.order_id) AS frequency_pesanan,
        ROUND(SUM(oi.sale_price), 2) AS monetary_nilai
    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
    WHERE oi.status = 'Complete'
    GROUP BY oi.user_id
),
rfm_kuantil AS (
    SELECT
        *,
        6 - NTILE(5) OVER (
            ORDER BY recency_hari ASC
        ) AS skor_recency,
        NTILE(5) OVER (
            ORDER BY monetary_nilai ASC
        ) AS skor_monetary
    FROM rfm
),
rfm_scored AS (
    SELECT
        *,
        CASE
            WHEN frequency_pesanan = 1 THEN 1
            WHEN frequency_pesanan = 2 THEN 3
            WHEN frequency_pesanan >= 3 THEN 5
        END AS skor_frequency
    FROM rfm_kuantil
),
segmentasi AS (
    SELECT
        *,
        CASE
            WHEN skor_recency >= 4
             AND skor_frequency >= 3
             AND skor_monetary >= 4 THEN 'Champions'
            WHEN skor_recency >= 3
             AND skor_frequency >= 3 THEN 'Loyal Customers'
            WHEN skor_recency >= 4
             AND skor_frequency = 1 THEN 'Recent Customers'
            WHEN skor_recency <= 2
             AND skor_frequency >= 3 THEN 'At Risk'
            WHEN skor_recency <= 2
             AND skor_frequency = 1 THEN 'Hibernating'
            ELSE 'Needs Attention'
        END AS segmen_pelanggan
    FROM rfm_scored
)
SELECT
    segmen_pelanggan,
    COUNT(*) AS jumlah_pelanggan,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS persentase_pelanggan,
    ROUND(AVG(recency_hari), 1) AS rata_rata_recency_hari,
    ROUND(AVG(frequency_pesanan), 2) AS rata_rata_frequency,
    ROUND(AVG(monetary_nilai), 2) AS rata_rata_monetary,
    ROUND(SUM(monetary_nilai), 2) AS total_monetary
FROM segmentasi
GROUP BY segmen_pelanggan
ORDER BY jumlah_pelanggan DESC;