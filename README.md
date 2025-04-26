# README

Take Home project for Omada Health: Glucose Metric Calculator

* Design Assumptions
- The current implementation assumes the viewer of the dashboard is using UTC time. When aggregating stats with the given definitions, using a different time zone will give different results. So as a follow-up, we may want to adjust the default time zone, or allow a user to set their own time zone.

* Follow-ups
- Caching for user stats. Consider rails-native read-through cache with Redis.
- Graphs/visualizations for user stats
- Authentication
- Allow a user to set their own time zone.

* Ruby version
ruby 3.2.2

* Rails version
Rails 8.0.2

* Database creation
bin/rails db:migrate

* Database initialization
bin/rails db:seed

* How to run the test suite
bundle exec rspec spec/

* Run local server
bin/rails server 

* API Usage
Params: member id, timeframe (last_7_days or current_month)
Example:
curl "http://127.0.0.1:3000/members/1/metrics?timeframe=last_7_days"

* Definitions
- Average Glucose (mg/dL): The sum of all glucose values in a specific time frame (week/month)
divided by the total number of readings available in that time frame.

- Time Above Range (%): The percentage of glucose readings in a specific time frame
(week/month) that are above 180 mg/dL.

- Time Below Range (%): The percentage of glucose readings in a specific time frame
(week/month) that are below 70 mg/dL.

- Last 7 Days: The “Last 7 days” includes available glucose data from 12:00:00am to 11:59:59pm
local time on the current day and the 6 prior days.

- Month: A “month” of glucose data includes all available glucose readings from 12:00:00am local
time on the first day of a calendar month to 11:59:59pm local time on the last day of that calendar
month.

- Change Since Prior Period (% or mg/dL): The difference between a metric for the current time
frame vs. the previous time frame (for example this month’s time in range compared to last
month’s). Obtained by subtracting the current metric from the previous one. If the metrics being
compared are percentages, the change will also be shown as a percentage.

* Assistant prompt summary:
