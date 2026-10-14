-- =====================================================================
-- Analisis penjualan: pertumbuhan nilai penjualan per kategori
-- Tujuan  : Membandingkan nilai penjualan Complete setiap kategori
--           produk pada 2025 dan 2026.
-- Sumber  : bigquery-public-data.thelook_ecommerce.order_items
--           digabung dengan products (kategori produk).
-- Periode : 1 Januari sampai 9 Oktober setiap tahun, agar perbandingan
--           adil karena data 2026 belum penuh.
-- Catatan : Kategori dengan penjualan 2025 sangat kecil bisa tampak
--           tumbuh sangat besar. Baca persentase bersama nilai
--           penjualannya. Zona waktu mengikuti created_at (UTC).
-- =====================================================================
WITH penjualan_kategori AS (
    SELECT
        p.category,
        EXTRACT(YEAR FROM oi.created_at) AS tahun,
        COUNT(*) AS jumlah_item,
        SUM(oi.sale_price) AS total_nilai_penjualan
    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
    INNER JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
        ON oi.product_id = p.id
    WHERE oi.status = 'Complete'
      AND EXTRACT(YEAR FROM oi.created_at) IN (2025, 2026)
      AND DATE(oi.created_at) <= DATE(EXTRACT(YEAR FROM oi.created_at), 10, 9)
    GROUP BY p.category, tahun
),

perbandingan AS (
    SELECT
        category,
        SUM(IF(tahun = 2025, total_nilai_penjualan, 0)) AS penjualan_2025,
        SUM(IF(tahun = 2026, total_nilai_penjualan, 0)) AS penjualan_2026,
        SUM(IF(tahun = 2025, jumlah_item, 0)) AS item_2025,
        SUM(IF(tahun = 2026, jumlah_item, 0)) AS item_2026
    FROM penjualan_kategori
    GROUP BY category
)

SELECT
    category,
    ROUND(penjualan_2025, 2) AS penjualan_2025,
    ROUND(penjualan_2026, 2) AS penjualan_2026,
    item_2025,
    item_2026,
    ROUND(
        SAFE_DIVIDE(penjualan_2026 - penjualan_2025, penjualan_2025) * 100,
        2
    ) AS pertumbuhan_persen
FROM perbandingan
ORDER BY pertumbuhan_persen DESC;