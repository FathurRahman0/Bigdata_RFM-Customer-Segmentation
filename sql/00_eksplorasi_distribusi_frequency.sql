-- Menghitung distribusi pelanggan berdasarkan jumlah pesanan Complete

WITH frekuensi_pelanggan AS (
    SELECT
        user_id,
        COUNT(DISTINCT order_id) AS frequency_pesanan
    FROM `bigquery-public-data.thelook_ecommerce.order_items`
    WHERE status = 'Complete'
    GROUP BY user_id
)

SELECT
    frequency_pesanan,
    COUNT(*) AS jumlah_pelanggan
FROM frekuensi_pelanggan
GROUP BY frequency_pesanan
ORDER BY frequency_pesanan;