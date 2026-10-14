-- =====================================================================
-- Analisis penjualan: pertumbuhan nilai penjualan tahunan
-- Tujuan  : Membandingkan nilai penjualan Complete setiap tahun dengan
--           tahun sebelumnya.
-- Sumber  : bigquery-public-data.thelook_ecommerce.order_items
-- Periode : 1 Januari sampai 9 Oktober setiap tahun, agar perbandingan
--           adil karena data tahun berjalan belum penuh.
-- Catatan : Zona waktu mengikuti kolom created_at (UTC). Pertumbuhan
--           tahun pertama bernilai NULL karena tidak ada pembanding.
-- =====================================================================
WITH penjualan_tahunan AS (
    SELECT
        EXTRACT(YEAR FROM oi.created_at) AS tahun,
        ROUND(SUM(oi.sale_price), 2) AS total_nilai_penjualan
    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
    WHERE oi.status = 'Complete'
      AND (
          EXTRACT(MONTH FROM oi.created_at) < 10
          OR (
              EXTRACT(MONTH FROM oi.created_at) = 10
              AND EXTRACT(DAY FROM oi.created_at) <= 9
          )
      )
    GROUP BY tahun
),

dengan_pembanding AS (
    SELECT
        tahun,
        total_nilai_penjualan,
        LAG(total_nilai_penjualan) OVER (ORDER BY tahun) AS penjualan_tahun_lalu
    FROM penjualan_tahunan
)

SELECT
    tahun,
    total_nilai_penjualan,
    penjualan_tahun_lalu,
    ROUND(
        SAFE_DIVIDE(
            total_nilai_penjualan - penjualan_tahun_lalu,
            penjualan_tahun_lalu
        ) * 100,
        2
    ) AS pertumbuhan_persen
FROM dengan_pembanding
ORDER BY tahun;