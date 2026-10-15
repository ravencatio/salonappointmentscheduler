#!/bin/bash

escape_sql() {
  printf '%s' "$1" | sed "s/'/''/g"
}

echo "~~~~~ MY SALON ~~~~~"
echo
echo "Welcome to My Salon, how can I help you?"
echo

SERVICE_NAME=""
while [[ -z "$SERVICE_NAME" ]]; do
  psql --username=freecodecamp --dbname=salon --tuples-only --no-align \
    --command="SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
  read SERVICE_ID_SELECTED

  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    SERVICE_NAME=$(psql --username=freecodecamp --dbname=salon --tuples-only --no-align \
      --command="SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
  fi

  if [[ -z "$SERVICE_NAME" ]]; then
    echo
    echo "I could not find that service. What would you like today?"
  fi
done

echo
echo "What's your phone number?"
read CUSTOMER_PHONE
CUSTOMER_PHONE_SQL=$(escape_sql "$CUSTOMER_PHONE")

CUSTOMER_ID=$(psql --username=freecodecamp --dbname=salon --tuples-only --no-align \
  --command="SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE_SQL';")

if [[ -z "$CUSTOMER_ID" ]]; then
  echo
  echo "I don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  CUSTOMER_NAME_SQL=$(escape_sql "$CUSTOMER_NAME")
  CUSTOMER_ID=$(psql --username=freecodecamp --dbname=salon --quiet --tuples-only --no-align \
    --command="INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE_SQL', '$CUSTOMER_NAME_SQL') RETURNING customer_id;")
else
  CUSTOMER_NAME=$(psql --username=freecodecamp --dbname=salon --tuples-only --no-align \
    --command="SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;")
fi

echo
echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME
SERVICE_TIME_SQL=$(escape_sql "$SERVICE_TIME")

psql --username=freecodecamp --dbname=salon --tuples-only --no-align \
  --command="INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME_SQL');" >/dev/null

echo
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."