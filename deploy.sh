# General vars
# PORTAINER_ENDPOINT=
# PORTAINER_API_KEY=

# Deployment vars
# ENDPOINT=
# STACK_NAME=
# STACK_FILE=
# STACK_ENV_FILE=

#computed vars 
ENDPOINT_ID=
STACK_ID=
SWARM_ID=

###########

### $1 - api path
function api_call() {
    local RES=$(curl -s --request GET --url ${PORTAINER_ENDPOINT}${1} --header "x-api-key: $PORTAINER_API_KEY")
    echo $RES
}

# $1 - method (POST/GET/PUT...)
# $2 - api path
# $3 - body
function api_call_json_body() {
    # echo "$1 $2 $3"
    local RES=$(curl -s --request $1 --url ${PORTAINER_ENDPOINT}${2} --header "x-api-key: $PORTAINER_API_KEY" --header "content-type: application/json" --data "$3")
    echo $RES
}

# $1 - endpoint name
function get_endpoint_id() {
    echo $(api_call "/api/endpoints?name=$1" | jq .[0].Id)
}

# $1 - endpoint id
# $2 - stack name
function get_stack_id() {
    echo $(api_call "/api/stacks?filter={'EndpointID':7}" | jq ".[] | select(.Name == \"$STACK_NAME\") | .Id")
}

# $1 - endpoint id
function get_swarm_id() {
    echo $(api_call "/api/endpoints/$1/docker/info" | jq .Swarm.Cluster.ID);
}

# $1 - env file
function getEnvJson() {

    local ENV_JSON=""
    while read LINE 
    do
        # echo "Line: $LINE"
        NAME=$(echo $LINE | cut -d "=" -f1)
        VALUE=$(echo $LINE | cut -d "=" -f2-)
        VALUE_JSON=$(node -e 'console.log(JSON.stringify(process.argv[1].replace(/^"(.*)"$/g,"$1")))' "$VALUE")

        ENV_JSON="$ENV_JSON,{\"name\":\"$NAME\", \"value\": $VALUE_JSON}"
    done < $1

    echo '['${ENV_JSON:1}']'
}

# COMPUTE ID VARS

# find endpoint ID
ENDPOINT_ID=$(get_endpoint_id $ENDPOINT)

# find stack id
STACK_ID=$(get_stack_id $ENDPOINT_ID $STACK_NAME)

# find swarm ID
SWARM_ID=$(get_swarm_id $ENDPOINT_ID);

# Display input vars
echo "PORTAINER_ENDPOINT=$PORTAINER_ENDPOINT"
echo "PORTAINER_API_KEY=$PORTAINER_API_KEY"
echo ""
echo "ENDPOINT=$ENDPOINT"
echo "STACK_NAME=$STACK_NAME"
echo "STACK_FILE=$STACK_FILE"
echo "STACK_ENV_FILE=$STACK_ENV_FILE"
echo ""
echo "ENDPOINT_ID=$ENDPOINT_ID";
echo "SWARM_ID=$SWARM_ID";
echo "STACK_ID=$STACK_ID";
echo ""

# load stack file
STACK_FILE_STRING=$(node -e "fs=require('fs');console.log(JSON.stringify(fs.readFileSync($STACK_FILE).toString()))")
echo "STACK_FILE_STRING=$STACK_FILE_STRING"
echo ""
echo ""
echo "======================================="
echo ""
echo ""

# load env file 

# check if stack is already deployed
if [ -z "$STACK_ID" ]
then
    # create stack
    echo "It seems $STACK_NAME stack was not deployed yet on $ENDPOINT cluster. Creating it...";

    PAYLOAD='{"env": '$(getEnvJson $STACK_ENV_FILE)',"fromAppTemplate":false, "name": "'$STACK_NAME'","swarmID": '$SWARM_ID', "stackFileContent": '${STACK_FILE_STRING}'}'
    echo "=== PAYLOAD ===";
    echo $PAYLOAD | jq
    echo "===============";
    api_call_json_body POST "/api/stacks?type=1&method=string&endpointId=$ENDPOINT_ID" "$PAYLOAD" | jq

else
    # update stack
    echo "Updating $STACK_NAME stack from $ENDPOINT cluster..."

    PAYLOAD='{"env": '$(getEnvJson $STACK_ENV_FILE)',"prune": true,"pullImage": true,"stackFileContent":'${STACK_FILE_STRING}'}'
    echo "=== PAYLOAD ===";
    echo $PAYLOAD | jq
    echo "===============";
    api_call_json_body PUT "/api/stacks/$STACK_ID?endpointId=$ENDPOINT_ID" "$PAYLOAD" | jq
fi  

