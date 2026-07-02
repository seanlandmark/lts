SELECT
    q.ID
   ,q.Date_of_Service
   ,q.Time_of_Service
   ,q.Patient_Name
   ,q.dob_value
   ,q.CSN_MRN
   ,q.FORM_ID
   ,q.LEVEL_OF_SERVICE
   ,q.PICKUP_LOCATION
   ,q.DROPOFF_LOCATION
   ,q.Miles
   ,q.NOTES
   ,q.WAIT_TIME
   ,q.ORDER_TOTAL_AMOUNT
   ,q.DISTANCE
   ,CONCAT(
        FLOOR(q.DURATION_MINUTES / 60),
        ':',
        LPAD(MOD(q.DURATION_MINUTES, 60), 2, '0')
    ) AS DURATION
FROM (
    SELECT
        p.ID
       ,DATE_FORMAT(p.post_date, '%m/%d/%Y') AS Date_of_Service
       ,DATE_FORMAT(p.post_date, '%h:%i %p') AS Time_of_Service
       ,CASE
            WHEN m.form_element_field IS NULL OR m.form_element_field = 'a:0:{}' THEN ''
            ELSE TRIM(CONCAT(
                SUBSTRING_INDEX(SUBSTRING_INDEX(m.form_element_field, '";}i:1;a:12:', 1), '"', -1),
                ' ',
                SUBSTRING_INDEX(SUBSTRING_INDEX(m.form_element_field, '";}i:2;a:12:', 1), '"', -1)
            ))
        END AS Patient_Name
       ,CASE
            WHEN m.form_element_field IS NULL OR m.form_element_field = 'a:0:{}' THEN ''
            ELSE SUBSTRING_INDEX(SUBSTRING_INDEX(m.form_element_field, '";}i:3;a:12:', 1), '"', -1)
        END AS dob_value
       ,CASE
            WHEN m.form_element_field IS NULL OR m.form_element_field = 'a:0:{}' THEN ''
            ELSE SUBSTRING_INDEX(SUBSTRING_INDEX(m.form_element_field, '";}i:4;a:12:', 1), '"', -1)
        END AS CSN_MRN
       ,m.booking_form_id AS FORM_ID
       ,CASE
            WHEN m.booking_form_id = '1806' THEN 'LH Wheelchair'
            WHEN m.booking_form_id = '1882' THEN 'LH Stretcher'
            WHEN m.booking_form_id = '1933' THEN 'LH Bariatric Wheelchair'
            WHEN m.booking_form_id = '1934' THEN 'LH Bariatric Stretcher'
            WHEN m.booking_form_id = '1044' THEN 'Main Trip'
            ELSE CONCAT('Unknown Form ', COALESCE(m.booking_form_id, ''))
        END AS LEVEL_OF_SERVICE
       ,COALESCE(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(m.coordinate, 'i:0;a:5:', -1), '";s:8:', 1), '"', -1), '') AS PICKUP_LOCATION
       ,COALESCE(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(m.coordinate, 'i:1;a:5:', -1), '";s:8:', 1), '"', -1), '') AS DROPOFF_LOCATION
       ,ROUND(
            COALESCE(CAST(NULLIF(m.base_location_distance, '') AS DECIMAL(12,4)), 0)
          + COALESCE(CAST(NULLIF(m.base_location_return_distance, '') AS DECIMAL(12,4)), 0),
            4
        ) AS Miles
       ,COALESCE(m.comment, '') AS NOTES
       ,'' AS WAIT_TIME
       ,ROUND(
            COALESCE(CAST(NULLIF(m.price_initial_value, '') AS DECIMAL(12,4)), 0)
          + ROUND(
                ROUND(COALESCE(CAST(NULLIF(m.base_location_distance, '') AS DECIMAL(12,4)), 0) / 1.609344, 1)
              * COALESCE(CAST(NULLIF(m.price_delivery_value, '') AS DECIMAL(12,4)), 0),
                2
            )
          + ROUND(
                ROUND(COALESCE(CAST(NULLIF(m.distance, '') AS DECIMAL(12,4)), 0) / 1.609344, 1)
              * COALESCE(CAST(NULLIF(m.price_distance_value, '') AS DECIMAL(12,4)), 0),
                2
            )
          + ROUND(
                ROUND(COALESCE(CAST(NULLIF(m.base_location_return_distance, '') AS DECIMAL(12,4)), 0) / 1.609344, 1)
              * COALESCE(CAST(NULLIF(m.price_delivery_return_value, '') AS DECIMAL(12,4)), 0),
                2
            )
          + COALESCE(CAST(NULLIF(m.price_round_value, '') AS DECIMAL(12,4)), 0),
            2
        ) AS ORDER_TOTAL_AMOUNT
       ,ROUND(
            ROUND(COALESCE(CAST(NULLIF(m.base_location_distance, '') AS DECIMAL(12,4)), 0) / 1.609344, 1)
          + ROUND(COALESCE(CAST(NULLIF(m.distance, '') AS DECIMAL(12,4)), 0) / 1.609344, 1)
          + ROUND(COALESCE(CAST(NULLIF(m.base_location_return_distance, '') AS DECIMAL(12,4)), 0) / 1.609344, 1),
            4
        ) AS DISTANCE
       ,(
            COALESCE(CASE WHEN m.base_location_duration REGEXP '^[0-9]+$' THEN CAST(m.base_location_duration AS UNSIGNED) ELSE 0 END, 0)
          + COALESCE(CASE WHEN m.base_location_return_duration REGEXP '^[0-9]+$' THEN CAST(m.base_location_return_duration AS UNSIGNED) ELSE 0 END, 0)
          + COALESCE(CASE WHEN m.duration REGEXP '^[0-9]+$' THEN CAST(m.duration AS UNSIGNED) ELSE 0 END, 0)
          + COALESCE(CASE WHEN m.waypoint_duration REGEXP '^[0-9]+$' THEN CAST(m.waypoint_duration AS UNSIGNED) ELSE 0 END, 0)
        ) AS DURATION_MINUTES
    FROM wpt9_posts p
    INNER JOIN (
        SELECT
            post_id
           ,MAX(CASE WHEN meta_key = 'chbs_form_element_field' THEN meta_value END) AS form_element_field
           ,MAX(CASE WHEN meta_key = 'chbs_booking_form_id' THEN meta_value END) AS booking_form_id
           ,MAX(CASE WHEN meta_key = 'chbs_base_location_distance' THEN meta_value END) AS base_location_distance
           ,MAX(CASE WHEN meta_key = 'chbs_base_location_return_distance' THEN meta_value END) AS base_location_return_distance
           ,MAX(CASE WHEN meta_key = 'chbs_distance' THEN meta_value END) AS distance
           ,MAX(CASE WHEN meta_key = 'chbs_comment' THEN meta_value END) AS comment
           ,MAX(CASE WHEN meta_key = 'chbs_price_delivery_value' THEN meta_value END) AS price_delivery_value
           ,MAX(CASE WHEN meta_key = 'chbs_price_delivery_return_value' THEN meta_value END) AS price_delivery_return_value
           ,MAX(CASE WHEN meta_key = 'chbs_price_initial_value' THEN meta_value END) AS price_initial_value
           ,MAX(CASE WHEN meta_key = 'chbs_price_distance_value' THEN meta_value END) AS price_distance_value
           ,MAX(CASE WHEN meta_key = 'chbs_price_distance_return_value' THEN meta_value END) AS price_distance_return_value
           ,MAX(CASE WHEN meta_key = 'chbs_price_round_value' THEN meta_value END) AS price_round_value
           ,MAX(CASE WHEN meta_key = 'chbs_coordinate' THEN meta_value END) AS coordinate
           ,MAX(CASE WHEN meta_key = 'chbs_booking_status_id' THEN meta_value END) AS booking_status_id
           ,MAX(CASE WHEN meta_key = 'chbs_duration' THEN meta_value END) AS duration
           ,MAX(CASE WHEN meta_key = 'chbs_base_location_duration' THEN meta_value END) AS base_location_duration
           ,MAX(CASE WHEN meta_key = 'chbs_base_location_return_duration' THEN meta_value END) AS base_location_return_duration
           ,MAX(CASE WHEN meta_key = 'chbs_waypoint_duration' THEN meta_value END) AS waypoint_duration
        FROM wpt9_postmeta
        WHERE meta_key IN (
            'chbs_form_element_field',
            'chbs_booking_form_id',
            'chbs_base_location_distance',
            'chbs_base_location_return_distance',
            'chbs_distance',
            'chbs_comment',
            'chbs_price_delivery_value',
            'chbs_price_delivery_return_value',
            'chbs_price_initial_value',
            'chbs_price_distance_value',
            'chbs_price_distance_return_value',
            'chbs_price_round_value',
            'chbs_coordinate',
            'chbs_booking_status_id',
            'chbs_duration',
            'chbs_base_location_duration',
            'chbs_base_location_return_duration',
            'chbs_waypoint_duration'
        )
        GROUP BY post_id
    ) m
        ON p.ID = m.post_id
    WHERE p.post_type = 'chbs_booking'
      AND p.post_status = 'publish'
      AND m.booking_status_id = '2'
      /* Optional date filter:
      AND p.post_date >= STR_TO_DATE('05/02/2025', '%m/%d/%Y')
      AND p.post_date <  DATE_ADD(STR_TO_DATE('05/15/2025', '%m/%d/%Y'), INTERVAL 1 DAY)
      */
) q;
