# google-fit-bp-average
This repo contains a tool to retrieve blood pressure data from Google Git and output the average.

## Assumptions
- You store your blood pressure data using [Google Fit app](https://www.google.com/fit/).

## How to run
- Retrieve access token with the following scopes for your Google Account. I use [OAuth 2.0 Playground](https://developers.google.com/oauthplayground/).
  - https://www.googleapis.com/auth/fitness.blood_pressure.read
- Set the access token to an environment variable named `GOOGLE_ACCESS_TOKEN`. This environment variable will be used by this script.
- Run the script: `$ ruby main.rb <START_DATE> <END_DATE>`.
  - START_DATE should look like `2021-01-20`: `YEAR-MONTH-DAY_OF_MONTH`.
