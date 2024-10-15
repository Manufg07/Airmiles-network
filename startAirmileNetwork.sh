#!/bin/bash

echo "------------Register the ca admin for each organization—----------------"

docker-compose -f docker/docker-compose-ca.yaml up -d
sleep 3

sudo chmod -R 777 organizations/

echo "------------Register and enroll the users for each organization—-----------"

chmod +x registerEnroll.sh

./registerEnroll.sh
sleep 3

echo "—-------------Build the infrastructure—-----------------"

docker-compose -f docker/docker-compose-4org.yaml up -d
sleep 3

echo "-------------Generate the genesis block—-------------------------------"

export FABRIC_CFG_PATH=${PWD}/config

export CHANNEL_NAME=airmilechannel

configtxgen -profile FourOrgsChannel -outputBlock ${PWD}/channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
sleep 2

echo "------ Create the application channel------"

export ORDERER_CA=${PWD}/organizations/ordererOrganizations/airmile.com/orderers/orderer.airmile.com/msp/tlscacerts/tlsca.airmile.com-cert.pem

export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/airmile.com/orderers/orderer.airmile.com/tls/server.crt

export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/airmile.com/orderers/orderer.airmile.com/tls/server.key

osnadmin channel join --channelID $CHANNEL_NAME --config-block ${PWD}/channel-artifacts/$CHANNEL_NAME.block -o localhost:7053 --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY
sleep 2

osnadmin channel list -o localhost:7053 --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY
sleep 2

export FABRIC_CFG_PATH=${PWD}/peercfg
export CORE_PEER_LOCALMSPID=AirlinesMSP
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/airlines.airmile.com/peers/peer0.airlines.airmile.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/airlines.airmile.com/users/Admin@airlines.airmile.com/msp
export CORE_PEER_ADDRESS=localhost:7051
export AIRLINES_PEER_TLSROOTCERT=${PWD}/organizations/peerOrganizations/airlines.airmile.com/peers/peer0.airlines.airmile.com/tls/ca.crt
export MERCHANTS_PEER_TLSROOTCERT=${PWD}/organizations/peerOrganizations/merchants.airmile.com/peers/peer0.merchants.airmile.com/tls/ca.crt
export BANKS_PEER_TLSROOTCERT=${PWD}/organizations/peerOrganizations/banks.airmile.com/peers/peer0.banks.airmile.com/tls/ca.crt
export CUSTOMERS_PEER_TLSROOTCERT=${PWD}/organizations/peerOrganizations/customers.airmile.com/peers/peer0.customers.airmile.com/tls/ca.crt
sleep 2

echo "—---------------Join airlines peer to the channel—-------------"

echo ${FABRIC_CFG_PATH}
sleep 2
peer channel join -b ${PWD}/channel-artifacts/${CHANNEL_NAME}.block
sleep 3

echo "-----channel List----"
peer channel list

echo "—-------------airlines anchor peer update—-----------"

# peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
# sleep 1

# cd channel-artifacts

# configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
# jq '.data.data[0].payload.data.config' config_block.json > config.json

# cp config.json config_copy.json

# jq '.channel_group.groups.Application.groups.AirlinesMSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.airlines.airmile.com","port": 7051}]},"version": "0"}}' config_copy.json > modified_config.json

# configtxlator proto_encode --input config.json --type common.Config --output config.pb
# configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
# configtxlator compute_update --channel_id ${CHANNEL_NAME} --original config.pb --updated modified_config.pb --output config_update.pb

# configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
# echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
# configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

# cd ..

# peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050  --ordererTLSHostnameOverride orderer.airmile.com --tls --cafile $ORDERER_CA
# sleep 1

# echo "—---------------package chaincode—-------------"

# peer lifecycle chaincode package airmiletoken.tar.gz --path ${PWD}/../Chaincode/chaincode-javascript --lang node --label airmiletoken_1.0
# sleep 1

# echo "—---------------install chaincode in airlines peer—-------------"

# peer lifecycle chaincode install airmiletoken.tar.gz
# sleep 3



# peer lifecycle chaincode queryinstalled
# sleep 1

# export CC_PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid airmiletoken.tar.gz)

# echo "—---------------Approve chaincode in airlines peer—-------------"

# peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --channelID $CHANNEL_NAME --name chaincode-javascript --version 1.0  --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
# sleep 2

peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
cd channel-artifacts

configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq '.data.data[0].payload.data.config' config_block.json > config.json

cp config.json config_copy.json
jq '.channel_group.groups.Application.groups.AirlinesMSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.airlines.airmile.com","port": 7051}]},"version": "0"}}' config_copy.json > modified_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id ${CHANNEL_NAME} --original config.pb --updated modified_config.pb --output config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

cd ..
peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --tls --cafile $ORDERER_CA
sleep 1

# Chaincode Packaging and Installation for Org1
echo "-------------Package and Install Chaincode for Org1-------------"

cp -r ../fabric-samples/asset-transfer-basic/chaincode-javascript ../Chaincode
peer lifecycle chaincode package basic.tar.gz --path ../Chaincode/chaincode-javascript/ --lang node --label basic_1.0

peer lifecycle chaincode install basic.tar.gz
sleep 3
peer lifecycle chaincode queryinstalled

export CC_PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid basic.tar.gz)
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --channelID $CHANNEL_NAME --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
sleep 1

export CORE_PEER_LOCALMSPID=MerchantsMSP
export CORE_PEER_ADDRESS=localhost:9051 
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/merchants.airmile.com/peers/peer0.merchants.airmile.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/merchants.airmile.com/users/Admin@merchants.airmile.com/msp

echo "—---------------Join merchants peer to the channel—-------------"

peer channel join -b ${PWD}/channel-artifacts/$CHANNEL_NAME.block
sleep 1
peer channel list

echo "—-------------merchants anchor peer update—-----------"

# peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
# sleep 1

# cd channel-artifacts

# configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
# jq '.data.data[0].payload.data.config' config_block.json > config.json
# cp config.json config_copy.json

# jq '.channel_group.groups.Application.groups.MerchantsMSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.merchants.airmile.com","port": 9051}]},"version": "0"}}' config_copy.json > modified_config.json

# configtxlator proto_encode --input config.json --type common.Config --output config.pb
# configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
# configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output config_update.pb

# configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
# echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
# configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

# cd ..

# peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050  --ordererTLSHostnameOverride orderer.airmile.com --tls --cafile $ORDERER_CA
# sleep 1

# echo "—---------------install chaincode in merchants peer—-------------"

# peer lifecycle chaincode install airmiletoken.tar.gz
# sleep 3

# peer lifecycle chaincode queryinstalled

# echo "—---------------Approve chaincode in merchants peer—-------------"

# peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --channelID $CHANNEL_NAME --name chaincode-javascript --version 1.0  --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
# sleep 1
peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
cd channel-artifacts

configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq '.data.data[0].payload.data.config' config_block.json > config.json

cp config.json config_copy.json
jq '.channel_group.groups.Application.groups.MerchantsMSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.airlines.airmile.com","port": 7051}]},"version": "0"}}' config_copy.json > modified_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id ${CHANNEL_NAME} --original config.pb --updated modified_config.pb --output config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

cd ..
peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --tls --cafile $ORDERER_CA
sleep 1

# Chaincode Packaging and Installation for Org1
echo "-------------Package and Install Chaincode for Org1-------------"

cp -r ../fabric-samples/asset-transfer-basic/chaincode-javascript ../Chaincode
peer lifecycle chaincode package basic.tar.gz --path ../Chaincode/chaincode-javascript/ --lang node --label basic_1.0

peer lifecycle chaincode install basic.tar.gz
sleep 3
peer lifecycle chaincode queryinstalled

export CC_PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid basic.tar.gz)
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --channelID $CHANNEL_NAME --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
sleep 1


export CORE_PEER_LOCALMSPID=BanksMSP 
export CORE_PEER_ADDRESS=localhost:11051 
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/banks.airmile.com/peers/peer0.banks.airmile.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/banks.airmile.com/users/Admin@banks.airmile.com/msp

echo "—---------------Join banks peer to the channel—-------------"

peer channel join -b ${PWD}/channel-artifacts/$CHANNEL_NAME.block
sleep 1
peer channel list

echo "—-------------banks anchor peer update—-----------"

# peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
# sleep 1

# cd channel-artifacts

# configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
# jq '.data.data[0].payload.data.config' config_block.json > config.json
# cp config.json config_copy.json

# jq '.channel_group.groups.Application.groups.BanksMSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.banks.airmile.com","port": 11051}]},"version": "0"}}' config_copy.json > modified_config.json

# configtxlator proto_encode --input config.json --type common.Config --output config.pb
# configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
# configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output config_update.pb

# configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
# echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
# configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

# cd ..

# peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050  --ordererTLSHostnameOverride orderer.airmile.com --tls --cafile $ORDERER_CA
# sleep 1

# peer channel getinfo -c $CHANNEL_NAME


# echo "—---------------install chaincode in banks peer—-------------"

# peer lifecycle chaincode install airmiletoken.tar.gz
# sleep 3

# peer lifecycle chaincode queryinstalled

# echo "—---------------Approve chaincode in banks peer—-------------"

# peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --channelID $CHANNEL_NAME --name chaincode-javascript --version 1.0  --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
# sleep 1
peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
cd channel-artifacts

configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq '.data.data[0].payload.data.config' config_block.json > config.json

cp config.json config_copy.json
jq '.channel_group.groups.Application.groups.BanksMSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.airlines.airmile.com","port": 7051}]},"version": "0"}}' config_copy.json > modified_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id ${CHANNEL_NAME} --original config.pb --updated modified_config.pb --output config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

cd ..
peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --tls --cafile $ORDERER_CA
sleep 1

# Chaincode Packaging and Installation for Org1
echo "-------------Package and Install Chaincode for Org1-------------"

cp -r ../fabric-samples/asset-transfer-basic/chaincode-javascript ../Chaincode
peer lifecycle chaincode package basic.tar.gz --path ../Chaincode/chaincode-javascript/ --lang node --label basic_1.0

peer lifecycle chaincode install basic.tar.gz
sleep 3
peer lifecycle chaincode queryinstalled

export CC_PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid basic.tar.gz)
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --channelID $CHANNEL_NAME --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
sleep 1

export CORE_PEER_LOCALMSPID=CustomersMSP 
export CORE_PEER_ADDRESS=localhost:12051 
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/customers.airmile.com/peers/peer0.customers.airmile.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/customers.airmile.com/users/Admin@customers.airmile.com/msp

echo "—---------------Join customers peer to the channel—-------------"

peer channel join -b ${PWD}/channel-artifacts/$CHANNEL_NAME.block
sleep 1
peer channel list

echo "—-------------customers anchor peer update—-----------"

# peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
# sleep 1

# cd channel-artifacts

# configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
# jq '.data.data[0].payload.data.config' config_block.json > config.json
# cp config.json config_copy.json

# jq '.channel_group.groups.Application.groups.CustomersMSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.customers.airmile.com","port": 9051}]},"version": "0"}}' config_copy.json > modified_config.json

# configtxlator proto_encode --input config.json --type common.Config --output config.pb
# configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
# configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output config_update.pb

# configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
# echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
# configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

# cd ..

# peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050  --ordererTLSHostnameOverride orderer.airmile.com --tls --cafile $ORDERER_CA
# sleep 1

# echo "—---------------install chaincode in customers peer—-------------"

# peer lifecycle chaincode install airmiletoken.tar.gz
# sleep 3

# peer lifecycle chaincode queryinstalled

# echo "—---------------Approve chaincode in customers peer—-------------"

# peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --channelID $CHANNEL_NAME --name chaincode-javascript --version 1.0  --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
# sleep 1
peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
cd channel-artifacts

configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq '.data.data[0].payload.data.config' config_block.json > config.json

cp config.json config_copy.json
jq '.channel_group.groups.Application.groups.CustomersMSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.airlines.airmile.com","port": 7051}]},"version": "0"}}' config_copy.json > modified_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id ${CHANNEL_NAME} --original config.pb --updated modified_config.pb --output config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

cd ..
peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --tls --cafile $ORDERER_CA
sleep 1

# Chaincode Packaging and Installation for Org1
echo "-------------Package and Install Chaincode for Org1-------------"

cp -r ../fabric-samples/asset-transfer-basic/chaincode-javascript ../Chaincode
peer lifecycle chaincode package basic.tar.gz --path ../Chaincode/chaincode-javascript/ --lang node --label basic_1.0

peer lifecycle chaincode install basic.tar.gz
sleep 3
peer lifecycle chaincode queryinstalled

export CC_PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid basic.tar.gz)
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --channelID $CHANNEL_NAME --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
sleep 1


# echo "—---------------Commit chaincode in banks peer—-------------"

# peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name chaincode-javascript --version 1.0 --sequence 1  --tls --cafile $ORDERER_CA --output json

# peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --channelID $CHANNEL_NAME --name chaincode-javascript --version 1.0 --sequence 1  --tls --cafile $ORDERER_CA --peerAddresses localhost:7051 --tlsRootCertFiles $AIRLINES_PEER_TLSROOTCERT --peerAddresses localhost:9051 --tlsRootCertFiles $MERCHANTS_PEER_TLSROOTCERT --peerAddresses localhost:11051 --tlsRootCertFiles $BANKS_PEER_TLSROOTCERT --peerAddresses localhost:12051 --tlsRootCertFiles $CUSTOMERS_PEER_TLSROOTCERT
# sleep 1
echo "-------------Commit the chaincode-------------"

peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --channelID $CHANNEL_NAME --name basic --version 1.0 --sequence 1 --tls --cafile $ORDERER_CA --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/airlines.airmile.com/peers/peer0.airlines.airmile.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/merchants.airmile.com/peers/peer0.merchants.airmile.com/tls/ca.crt --peerAddresses localhost:11051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/banks.airmile.com/peers/peer0.banks.airmile.com/tls/ca.crt --peerAddresses localhost:12051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/customers.airmile.com/peers/peer0.customers.airmile.com/tls/ca.crt
sleep 2

peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name basic --cafile $ORDERER_CA


# peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name chaincode-javascript --cafile $ORDERER_CApeer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --tls --cafile "${PWD}/organizations/ordererOrganizations/airmile.com/orderers/orderer.airmile.com/msp/tlscacerts/tlsca.airmile.com-cert.pem" -C airlines -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/airlines.airmile.com/peers/peer0.airlines.airmile.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/merchants.airmile.com/peers/peer0.merchants.airmile.com/tls/ca.crt" -c '{"function":"InitLedger","Args":[]}'

# peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.airmile.com --tls --cafile "${PWD}/organizations/ordererOrganizations/airmile.com/orderers/orderer.airmile.com/msp/tlscacerts/tlsca.airmile.com-cert.pem" -C airmilechannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/airlines.airmile.com/peers/peer0.airlines.airmile.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/merchants.airmile.com/peers/peer0.merchants.airmile.com/tls/ca.crt" --peerAddresses localhost:11051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/banks.airmile.com/peers/peer0.banks.airmile.com/tls/ca.crt" --peerAddresses localhost:12051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/customers.airmile.com/peers/peer0.customers.airmile.com/tls/ca.crt" -c '{"function":"InitLedger","Args":[]}'
# peer chaincode query -C realestatecorp -n basic -c '{"function":"ReadAsset","Args":["asset5"]}'