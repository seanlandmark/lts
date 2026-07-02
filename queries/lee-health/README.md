# Lee Health Invoice SQL

Production CHBS booking invoice extract for Lee Health / Prompt Care Transport.

## Artifact columns

`ID`, `Date_of_Service`, `Time_of_Service`, `Patient_Name`, `dob_value`, `CSN_MRN`, `FORM_ID`, `LEVEL_OF_SERVICE`, `PICKUP_LOCATION`, `DROPOFF_LOCATION`, `Miles`, `NOTES`, `WAIT_TIME`, `ORDER_TOTAL_AMOUNT`, `DISTANCE`, `DURATION`.

## Validated calculation model

`ORDER_TOTAL_AMOUNT` and `DISTANCE` use a three-leg route model:

1. HQ/base to pickup
2. pickup to dropoff
3. dropoff to HQ/base

CHBS distance meta values are converted from kilometers to miles with `distance_km / 1.609344`, rounded to one decimal mile per leg to match the application line-item display. `DURATION` sums base, trip, return, and waypoint duration components and formats as `H:MM`.
