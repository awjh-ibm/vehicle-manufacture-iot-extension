#!/bin/bash
BASEDIR=$(dirname "$0")

if [ $BASEDIR = '.' ]
then
    BASEDIR=$(pwd)
elif [ ${BASEDIR:0:2} = './' ]
then
    BASEDIR=$(pwd)${BASEDIR:1}
elif [ ${BASEDIR:0:1} = '/' ]
then
    BASEDIR=${BASEDIR}
else
    BASEDIR=$(pwd)/${BASEDIR}
fi

NETWORK_DOCKER_COMPOSE_DIR=$BASEDIR/network/docker-compose

#################
# SETUP LOGGING #
#################
LOG_PATH=$BASEDIR/logs
mkdir $LOG_PATH

exec > >(tee -i $LOG_PATH/install.log)
exec 2>&1

echo "###########################"
echo "# set env vars for docker #"
echo "###########################"
export $(cat $NETWORK_DOCKER_COMPOSE_DIR/.env | xargs)

echo "####################################################"
echo "# COPY AND TEMPLATE LOCAL AND APPS connection.json #"
echo "####################################################"

CONNECTION_TMPL_LOCATION="${BASEDIR}/network/connection.tmpl.json"
APPS_DIR="${BASEDIR}/../apps"

LOCAL_MSP="${BASEDIR}/network/crypto-material/crypto-config"
DOCKER_MSP="/msp"

PEER_LOCAL_URL="localhost"

ORDERER_DOCKER_URL="orderer.example.com"
ORDERER_LOCAL_URL=$PEER_LOCAL_URL
ORDERER_PORT="7050"

ARIUM_ORG_NAME="Arium"
ARIUM_APP_NAME="manufacturer"
ARIUM_PEER_DOCKER_URL="peer0.arium.com"
ARIUM_PEER_PORT="7051"
ARIUM_PEER_EVENT_PORT="7053"
ARIUM_CA_DOCKER_URL="tlsca.arium.com"
ARIUM_CA_DOCKER_PORT="7054"
ARIUM_CA_LOCAL_PORT="7054"

VDA_ORG_NAME="VDA"
VDA_APP_NAME="regulator"
VDA_PEER_DOCKER_URL="peer0.vda.com"
VDA_PEER_PORT="8051"
VDA_PEER_EVENT_PORT="8053"
VDA_CA_DOCKER_URL="tlsca.vda.com"
VDA_CA_DOCKER_PORT="7054"
VDA_CA_LOCAL_PORT="8054"

PRINCE_ORG_NAME="PrinceInsurance"
PRINCE_APP_NAME="insurer"
PRINCE_INSURANCE_PEER_DOCKER_URL="peer0.prince-insurance.com"
PRINCE_INSURANCE_PEER_PORT="9051"
PRINCE_INSURANCE_PEER_EVENT_PORT="9053"
PRINCE_INSURANCE_CA_DOCKER_URL="tlsca.prince-insurance.com"
PRINCE_INSURANCE_CA_DOCKER_PORT="7054"
PRINCE_INSURANCE_CA_LOCAL_PORT="9054"

ORGS=("ARIUM" "VDA" "PRINCE") # MUST MATCH STARTS OF VARS ABOVE TO MAKE LOOPS WORK
TYPES=("DOCKER" "LOCAL") # MUST MATCH THE _TYPE IN THE ABOVE VARS TO MAKE LOOPS WORK

# SETS LOCALHOST FOR ALL OF THE ORGS
for ORG in $ORGS; do
    eval "${ORG}_PEER_LOCAL_URL"="$PEER_LOCAL_URL"
    eval "${ORG}_CA_LOCAL_URL"="$PEER_LOCAL_URL"
done

LOCAL_CONNECTION_NAME="local_connection.json"
DOCKER_CONNECTION_NAME="connection.json"

SHARED_CONNECTION_TMP="$BASEDIR/tmp/shared_connection.json"
LOCAL_CONNECTION_TMP="$BASEDIR/tmp/$LOCAL_CONNECTION_NAME"
DOCKER_CONNECTION_TMP="$BASEDIR/tmp/$DOCKER_CONNECTION_NAME"

mkdir -p $BASEDIR/tmp

##############
# SET SHARED #
##############
touch $SHARED_CONNECTION_TMP
cp $CONNECTION_TMPL_LOCATION $SHARED_CONNECTION_TMP
sed -i '' -e 's#{{ORDERER_PORT}}#'${ORDERER_PORT}'#g' $SHARED_CONNECTION_TMP

for ORG in "${ORGS[@]}"; do
    PEER_PORT="${ORG}_PEER_PORT"
    PEER_EVENT_PORT="${ORG}_PEER_EVENT_PORT"

    sed -i '' -e 's#{{'${PEER_PORT}'}}#'${!PEER_PORT}'#g' $SHARED_CONNECTION_TMP
    sed -i '' -e 's#{{'${PEER_EVENT_PORT}'}}#'${!PEER_EVENT_PORT}'#g' $SHARED_CONNECTION_TMP
done

#####################
# SET OTHER FORMATS #
#####################
for TYPE in "${TYPES[@]}"; do
    TMP_VAR="${TYPE}_CONNECTION_TMP"
    TMP_FILE=${!TMP_VAR}

    touch $TMP_FILE
    cp $SHARED_CONNECTION_TMP $TMP_FILE

    ORDER_URL="ORDERER_${TYPE}_URL"
    sed -i '' -e 's#{{ORDERER_URL}}#'${!ORDER_URL}'#g' $TMP_FILE

    MSP_DIR="${TYPE}_MSP"
    sed -i '' -e 's#{{MSP_DIR}}#'${!MSP_DIR}'#g' $TMP_FILE

    for ORG in "${ORGS[@]}"; do
        PEER_URL="${ORG}_PEER_${TYPE}_URL"
        CA_URL="${ORG}_CA_${TYPE}_URL"
        CA_PORT="${VDA}_CA_${TYPE}_PORT"

        sed -i '' -e 's#{{'${ORG}'_PEER_URL}}#'${!PEER_URL}'#g' $TMP_FILE
        sed -i '' -e 's#{{'${ORG}'_CA_URL}}#'${!CA_URL}'#g' $TMP_FILE
        sed -i '' -e 's#{{'${ORG}'_CA_PORT}}#'${!CA_PORT}'#g' $TMP_FILE
    done
done

rm -f $SHARED_CONNECTION_TMP

for ORG in "${ORGS[@]}"; do
    ORG_NAME="${ORG}_ORG_NAME"
    APP_NAME="${ORG}_APP_NAME"

    OUTPUT_FOLDER="$APPS_DIR/${!APP_NAME}/vehiclemanufacture_fabric"

    for TYPE in "${TYPES[@]}"; do
        OUTPUT_FILE_NAME="${TYPE}_CONNECTION_NAME"
        TMP_FILE="${TYPE}_CONNECTION_TMP"

        sed 's#{{ORGANISATION}}#'${!ORG_NAME}'#g' ${!TMP_FILE} > $OUTPUT_FOLDER/${!OUTPUT_FILE_NAME}
    done
done

for TYPE in "${TYPES[@]}"; do
    TMP_FILE="${TYPE}_CONNECTION_TMP"
    rm -f ${!TMP_FILE}
done

# echo "#####################"
# echo "# CHAINCODE INSTALL #"
# echo "#####################"

# docker-compose -f $NETWORK_DOCKER_COMPOSE_DIR/docker-compose-cli.yaml up -d

# docker exec cli bash -c "apk add nodejs nodejs-npm python make g++"
# docker exec cli bash -c 'cd /etc/hyperledger/contract; npm install; npm run build'

# docker-compose -f $NETWORK_DOCKER_COMPOSE_DIR/docker-compose-cli.yaml down --volumes

# echo "###################"
# echo "# BUILD CLI_TOOLS #"
# echo "###################"
# cd $BASEDIR/cli_tools
# npm install
# npm run build
# cd $BASEDIR

echo "#############################"
echo "# CLEAN ENV VARS FOR DOCKER #"
echo "#############################"
unset $(cat $NETWORK_DOCKER_COMPOSE_DIR/.env | sed -E 's/(.*)=.*/\1/' | xargs)

echo "####################"
echo "# INSTALL COMPLETE #"
echo "####################"
