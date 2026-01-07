WITH som_bibs AS (
  SELECT
    l.bib_record_id

  FROM sierra_view.item_record i
  JOIN sierra_view.bib_record_item_record_link l
    ON i.id = l.item_record_id 
  LEFT JOIN sierra_view.varfield v
    ON i.id = v.record_id AND v.varfield_type_code = 'v'

  WHERE i.location_code ~ '^so'
  GROUP BY 1
  HAVING COUNT(i.id) FILTER(WHERE v.field_content IS NOT NULL) = 0
),

isbn AS (
  SELECT
    s.record_id,
    COALESCE(STRING_AGG(DISTINCT SUBSTRING(s.content FROM '^\d{9,12}[\d|X]'),'|'),'') AS "isbns"
  FROM som_bibs b
  JOIN sierra_view.subfield s
    ON b.bib_record_id = s.record_id
	 AND s.marc_tag = '020' AND s.tag = 'a'
  GROUP BY 1
)

SELECT
  i.record_id,
  COALESCE(SUBSTRING(o.content FROM '[0-9]+'),'') AS "001",
  i.isbns AS "020"

FROM isbn i
JOIN sierra_view.bib_record_property b
  ON i.record_id = b.bib_record_id
  AND b.material_code IN ('2','f','9','a','e','o','p','t')
LEFT JOIN sierra_view.subfield o
  ON i.record_id = o.record_id
  AND o.marc_tag = '001'
