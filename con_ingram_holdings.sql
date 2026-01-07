--print items and orders for Concord

WITH not_multi_volume AS (
  SELECT l.bib_record_id
  
  FROM sierra_view.bib_record_item_record_link l
  LEFT JOIN sierra_view.varfield v
    ON l.item_record_id = v.record_id
    AND v.varfield_type_code = 'v'
    
  GROUP BY 1
  HAVING COUNT(l.item_record_id) FILTER(WHERE v.field_content IS NOT NULL) = 0
),

con_bibs AS (
  SELECT
    DISTINCT inner_query.bib_record_id
  FROM (
    SELECT
      l.bib_record_id

      FROM not_multi_volume nmv
      JOIN sierra_view.bib_record_item_record_link l
        ON nmv.bib_record_id = l.bib_record_id
      JOIN sierra_view.item_record i
        ON l.item_record_id = i.id

      WHERE i.location_code ~ '^co'

    UNION

    SELECT
      ol.bib_record_id
    
    FROM not_multi_volume nmv
    JOIN sierra_view.bib_record_order_record_link ol
      ON nmv.bib_record_id = ol.bib_record_id
    JOIN sierra_view.order_record o
      ON ol.order_record_id = o.id

    WHERE o.accounting_unit_code_num = '8'
  )inner_query 
),

isbn AS (
SELECT
  s.record_id,
  COALESCE(STRING_AGG(DISTINCT SUBSTRING(s.content FROM '^\d{9,12}[\d|X]'),'|'),'') AS "isbns"
  FROM con_bibs b
  JOIN sierra_view.subfield s
    ON b.bib_record_id = s.record_id
	 AND s.marc_tag = '020'
	 AND s.tag = 'a'
  GROUP BY 1
)


SELECT
  i.record_id,
  COALESCE(SUBSTRING(o.content FROM '[0-9]+'),'') AS "001",
  i.isbns AS "020"

FROM isbn i
JOIN sierra_view.bib_record_property b
  ON i.record_id = b.bib_record_id 
LEFT JOIN sierra_view.subfield o
  ON i.record_id = o.record_id
  AND o.marc_tag = '001'

WHERE b.material_code IN ('2','f','9','a','e','o','p','t')
