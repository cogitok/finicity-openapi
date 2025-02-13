#!/bin/bash

api_error() {
   echo ""
   echo "Response: $1"
   echo ""
   echo "API call failed! Check {partnerId}, {partnerSecret} and {appKey} and make sure you are located in the US, UK or Canada."
   enter_to_exit
}

enter_to_exit() {
  read -p "Press [Enter] to exit..."
  exit
}

if [ "$#" -ne 3 ]; then
    echo "Usage: ./setup.sh {partnerId} {partnerSecret} {appKey}"
    enter_to_exit
fi

echo "Step 1 - Creating access token ..."
token_response=$(curl -s --location --request POST 'https://api.finicity.com/aggregation/v2/partners/authentication' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--header 'Finicity-App-Key:'$3 \
--data-raw '{ "partnerId": "'$1'", "partnerSecret": "'$2'" }')

# {"token":"P09NAglkaBTyJrHoFGmL"}
if [[ "$token_response" != *"token"* ]]; then 
  api_error "$token_response"
fi;

token=$(echo $token_response | sed -E 's/\{"token":"(.*)"\}/\1/')
echo "Access token: "$token
echo ""

echo "Step 2 - Creating test customer ..."
customer_response=$(curl -s --location --request POST 'https://api.finicity.com/aggregation/v2/customers/testing' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--header 'Finicity-App-Key:'$3 \
--header 'Finicity-App-Token:'$token \
--data-raw '{ "username": "customerusername_'$RANDOM$RANDOM'" }')

# {"id":"5026948632","username":"customerusername1","createdDate":"1649244189"}
if [[ "$customer_response" != *"username"* ]]; then 
  api_error "$customer_response"
fi;

customer_id=$(echo $customer_response | sed -E 's/\{"id":"([0-9]*).*/\1/')
echo "Customer ID: "$customer_id
echo ""

echo "Step 3 - Generating connect URL ..."
connect_url_response=$(curl -s --location --request POST 'https://api.finicity.com/connect/v2/generate' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--header 'Finicity-App-Key:'$3 \
--header 'Finicity-App-Token:'$token \
--data-raw '{ "partnerId": "'$1'", "customerId": "'$customer_id'" }')

# {"link":"https://..."}
link=$(echo $connect_url_response | sed -E 's/\{"link":"(.*)"\}/\1/')
echo "URL created"

echo ""
echo "Step 4 - Ctrl+click on the URL below, search for 'FinBank Profiles - A', then sign in with 'profile_03'/'profile_03' and add all available accounts"
echo ""
echo $link
echo ""
read -p "After you see 'Your submission was successful. Thank you!', press [Enter] to continue ..."

echo ""
echo "Step 5 - Refreshing accounts ..."
accounts_response=$(curl -s --location --request POST 'https://api.finicity.com/aggregation/v1/customers/'$customer_id'/accounts' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--header 'Finicity-App-Key:'$3 \
--header 'Finicity-App-Token:'$token \
--data-raw '{}')

# { "accounts": [...]}
echo "Accounts refreshed"

echo ""
echo "APP_KEY: "$3
echo "CUSTOMER_ID: "$customer_id
echo "PARTNER_ID: "$1
echo "PARTNER_SECRET: "$2
echo ""

echo "To run the API client tests:"
echo ""
echo "git clone https://github.com/Mastercard/finicity-openapi"
echo "cd finicity-openapi/tests"
echo "mvn clean test -DpartnerId="$1" -DpartnerSecret="$2" -DappKey="$3" -DcustomerId="$customer_id""
echo ""

echo "To run the Postman Collection:"
echo ""
echo "git clone https://github.com/Mastercard/finicity-postman"
echo "cd finicity-postman"
echo "npx newman run finicity.postman_collection.json --env-var partnerId="$1" --env-var partnerSecret="$2" --env-var appKey="$3" --env-var customerId="$customer_id" --folder 'All APIs'"
echo ""
enter_to_exit