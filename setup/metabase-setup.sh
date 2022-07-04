#!/bin/sh

echo "seting up $1"
# get deps
apk add curl jq
# get the wait-until script
curl -L https://raw.githubusercontent.com/nickjj/wait-until/v0.2.0/wait-until -o /usr/local/bin/wait-until && \
chmod +x /usr/local/bin/wait-until
# run the script and everything else
wait-until "echo 'Checking if Metabase is ready' && curl -s http://$1/api/health | grep -ioE 'ok'" 60 && \
if curl -s http://$1/api/session/properties | jq -r '."setup-token"' | grep -ioE "null"; then echo 'Instance already configured, exiting (or <v43)'; else \
echo 'Setting up the instance' && \
token=$(curl -s http://$1/api/session/properties | jq -r '."setup-token"') && \
echo 'Setup token fetched, now configuring with:' && \
echo "{'token':'$token','user':{'first_name':'a','last_name':'b','email':'a@b.com','site_name':'metabot1','password':'metabot1','password_confirm':'metabot1'},'database':null,'invite':null,'prefs':{'site_name':'metabot1','site_locale':'en','allow_tracking':'false'}}" > file.json && \
sed 's/'\''/\"/g' file.json > file2.json && \
cat file2.json && \
sessionToken=$(curl -s http://$1/api/setup -H 'Content-Type: application/json' --data-binary @file2.json | jq -r '.id') && echo ' < Admin session token, exiting' && \
# creating a postgres
curl -s -X DELETE http://$1/api/database/1 -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" && \
curl -s -X POST http://$1/api/database -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"engine":"postgres","name":"pg","details":{"host":"postgres-data1-logging","port":"5432","dbname":"sample","user":"metabase","password":"metasample123","schema-filters-type":"all","ssl":false,"tunnel-enabled":false,"advanced-options":false},"is_full_sync":true}' && \
curl -s -X POST http://$1/api/database -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"engine":"postgres","name":"pg_ssh","details":{"host":"postgres-data1-logging","port":5432,"dbname":"sample","user":"metabase","password":"metasample123","schema-filters-type":"all","ssl":false,"tunnel-enabled":true,"tunnel-host":"ssh-logging","tunnel-port":2222,"tunnel-user":"metabase","tunnel-auth-option":"password","tunnel-pass":"mysecretpassword","advanced-options":false},"is_full_sync":true}' && \
curl -s -X POST http://$1/api/database -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"engine":"postgres","name":"telemetry","details":{"host":"telemetry-logging","port":5432,"dbname":"metabase_telemetry","user":"metabase","password":"mysecretpassword","schema-filters-type":"inclusion","schema-filters-patterns":"public","ssl":false,"tunnel-enabled":false,"advanced-options":false},"is_full_sync":true}' && \
curl -s -X POST http://$1/api/database -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"engine":"mysql","name":"mariadb","details":{"host":"mariadb-data-logging","port":3306,"dbname":"sample","user":"metabase","password":"metasample123","ssl":false,"tunnel-enabled":true,"tunnel-host":"ssh-logging","tunnel-port":2222,"tunnel-user":"metabase","tunnel-auth-option":"password","tunnel-pass":"mysecretpassword","advanced-options":false},"is_full_sync":true}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"Orders, Sum of ,Subtotal, Sum of ,Tax, and Sum of Total, Grouped by Product → Category and User → Source","dataset_query":{"database":2,"query":{"source-table":5,"aggregation":[["sum",["field",39,null]],["sum",["field",40,null]],["sum",["field",37,null]]],"breakout":[["field",61,{"source-field":43}],["field",56,{"source-field":44}]]},"type":"query"},"display":"pivot","description":null,"visualization_settings":{"pivot_table.column_split":{"rows":[["field",56,{"source-field":44}]],"columns":[["field",61,{"source-field":43}]],"values":[["aggregation",0],["aggregation",1],["aggregation",2]]}},"collection_id":null,"result_metadata":[{"description":"The type of product, valid values include: Doohicky, Gadget, Gizmo and Widget","semantic_type":null,"coercion_strategy":null,"name":"pivot-grouping","settings":null,"field_ref":["expression","pivot-grouping"],"effective_type":"type/Text","id":61,"display_name":"pivot-grouping","fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":3,"q1":3,"q3":3,"max":3,"sd":null,"avg":3}}},"base_type":"type/Integer"},{"description":"The channel through which we acquired this user. Valid values include: Affiliate, Facebook, Google, Organic and Twitter","semantic_type":null,"coercion_strategy":null,"name":"sum","settings":null,"field_ref":["aggregation",0],"effective_type":"type/Text","id":56,"display_name":"Sum of Subtotal","fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":1448188.1658779324,"q1":1448188.1658779324,"q3":1448188.1658779324,"max":1448188.1658779324,"sd":null,"avg":1448188.1658779324}}},"base_type":"type/Float"},{"display_name":"Sum of Tax","field_ref":["aggregation",1],"name":"sum_2","base_type":"type/Float","effective_type":"type/Integer","semantic_type":null,"fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":72388.33999999962,"q1":72388.33999999962,"q3":72388.33999999962,"max":72388.33999999962,"sd":null,"avg":72388.33999999962}}}},{"display_name":"Sum of Total","semantic_type":null,"settings":null,"field_ref":["aggregation",2],"name":"sum_3","base_type":"type/Float","effective_type":"type/Float","fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":1595328.1251600615,"q1":1595328.1251600615,"q3":1595328.1251600615,"max":1595328.1251600615,"sd":null,"avg":1595328.1251600615}}}}]}' && \
curl -s -X POST http://$1/api/dashboard -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"abc","collection_id":null}' && \
curl -s -X POST http://$1/api/dashboard/1/cards -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"cardId":1}' && \
curl -s -X POST http://$1/api/dashboard/1/cards -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"cardId":1}' && \
curl -s -X PUT http://$1/api/dashboard/1/cards -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"cards":[{"id":4,"card_id":1,"row":0,"col":0,"sizeX":4,"sizeY":4,"series":[],"visualization_settings":{},"parameter_mappings":[]},{"id":5,"card_id":1,"row":0,"col":4,"sizeX":4,"sizeY":4,"series":[],"visualization_settings":{},"parameter_mappings":[]}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"COUNT ORDERS","dataset_query":{"type":"native","native":{"query":"select count(*) from `ORDERS`","template-tags":{}},"database":5},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"count(*)","field_ref":["field","count(*)",{"base-type":"type/BigInteger"}],"name":"count(*)","base_type":"type/BigInteger","effective_type":"type/BigInteger","semantic_type":null,"fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":18760,"q1":18760,"q3":18760,"max":18760,"sd":null,"avg":18760}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"SUM TOTAL","dataset_query":{"type":"native","native":{"query":"select sum(total) from `ORDERS`","template-tags":{}},"database":5},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"sum(total)","field_ref":["field","sum(total)",{"base-type":"type/Float"}],"name":"sum(total)","base_type":"type/Float","effective_type":"type/Float","semantic_type":null,"fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":1595328.1251600615,"q1":1595328.1251600615,"q3":1595328.1251600615,"max":1595328.1251600615,"sd":null,"avg":1595328.1251600615}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"SUM SUBTOTAL","dataset_query":{"type":"native","native":{"query":"select sum(subtotal) from `ORDERS`","template-tags":{}},"database":5},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"sum(subtotal)","field_ref":["field","sum(subtotal)",{"base-type":"type/Float"}],"name":"sum(subtotal)","base_type":"type/Float","effective_type":"type/Float","semantic_type":null,"fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":1448188.1658779324,"q1":1448188.1658779324,"q3":1448188.1658779324,"max":1448188.1658779324,"sd":null,"avg":1448188.1658779324}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"SUM TAX","dataset_query":{"type":"native","native":{"query":"select sum(tax) from `ORDERS`","template-tags":{}},"database":5},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"sum(tax)","field_ref":["field","sum(tax)",{"base-type":"type/Float"}],"name":"sum(tax)","base_type":"type/Float","effective_type":"type/Float","semantic_type":null,"fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":72388.33999999962,"q1":72388.33999999962,"q3":72388.33999999962,"max":72388.33999999962,"sd":null,"avg":72388.33999999962}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"SUM DISCOUNT","dataset_query":{"type":"native","native":{"query":"select sum(discount) from `ORDERS`","template-tags":{}},"database":5},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"sum(discount)","field_ref":["field","sum(discount)",{"base-type":"type/Float"}],"name":"sum(discount)","base_type":"type/Float","effective_type":"type/Float","semantic_type":"type/Discount","fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":9954.822827272115,"q1":9954.822827272115,"q3":9954.822827272115,"max":9954.822827272115,"sd":null,"avg":9954.822827272115}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"SUM QUANTITY","dataset_query":{"type":"native","native":{"query":"select sum(QUANTITY) from `ORDERS`","template-tags":{}},"database":5},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"sum(QUANTITY)","field_ref":["field","sum(QUANTITY)",{"base-type":"type/Decimal"}],"name":"sum(QUANTITY)","base_type":"type/Decimal","effective_type":"type/Decimal","semantic_type":null,"fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":69540,"q1":69540,"q3":69540,"max":69540,"sd":null,"avg":69540}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"AVG REVIEWS","dataset_query":{"type":"native","native":{"query":"select AVG(rating) from `REVIEWS`","template-tags":{}},"database":5},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"AVG(rating)","field_ref":["field","AVG(rating)",{"base-type":"type/Decimal"}],"name":"AVG(rating)","base_type":"type/Decimal","effective_type":"type/Decimal","semantic_type":"type/Score","fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":3.9874,"q1":3.9874,"q3":3.9874,"max":3.9874,"sd":null,"avg":3.9874}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"REVIEWS","dataset_query":{"type":"native","native":{"query":"select REVIEWER, RATING from `REVIEWS`","template-tags":{}},"database":5},"display":"table","description":null,"visualization_settings":{"table.pivot_column":"RATING","table.cell_column":"REVIEWER"},"collection_id":null,"result_metadata":[{"display_name":"REVIEWER","field_ref":["field","REVIEWER",{"base-type":"type/Text"}],"name":"REVIEWER","base_type":"type/Text","effective_type":"type/Text","semantic_type":null,"fingerprint":{"global":{"distinct-count":1076,"nil%":0},"type":{"type/Text":{"percent-json":0,"percent-url":0,"percent-email":0,"percent-state":0.001798561151079137,"average-length":9.972122302158274}}}},{"display_name":"RATING","field_ref":["field","RATING",{"base-type":"type/Integer"}],"name":"RATING","base_type":"type/Integer","effective_type":"type/Integer","semantic_type":"type/Score","fingerprint":{"global":{"distinct-count":5,"nil%":0},"type":{"type/Number":{"min":1,"q1":3.54744353181696,"q3":4.764807071650455,"max":5,"sd":1.0443899855660577,"avg":3.987410071942446}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"ORDERS","dataset_query":{"type":"native","native":{"query":"select TOTAL, QUANTITY from `ORDERS`","template-tags":{}},"database":5},"display":"table","description":null,"visualization_settings":{"table.pivot_column":"QUANTITY","table.cell_column":"TOTAL"},"collection_id":null,"result_metadata":[{"display_name":"TOTAL","field_ref":["field","TOTAL",{"base-type":"type/Float"}],"name":"TOTAL","base_type":"type/Float","effective_type":"type/Float","semantic_type":null,"fingerprint":{"global":{"distinct-count":2000,"nil%":0},"type":{"type/Number":{"min":15.968675813101619,"q1":52.72185432487288,"q3":111.76311166117706,"max":169.17982252162366,"sd":34.8393444705293,"avg":82.37024915648372}}}},{"display_name":"QUANTITY","field_ref":["field","QUANTITY",{"base-type":"type/Integer"}],"name":"QUANTITY","base_type":"type/Integer","effective_type":"type/Integer","semantic_type":"type/Quantity","fingerprint":{"global":{"distinct-count":27,"nil%":0},"type":{"type/Number":{"min":0,"q1":1.7680340018414042,"q3":5.078814523684541,"max":68,"sd":3.5020851003402265,"avg":3.6885}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PEOPLE","dataset_query":{"type":"native","native":{"query":"select EMAIL, SOURCE from `PEOPLE`","template-tags":{}},"database":5},"display":"table","description":null,"visualization_settings":{"table.pivot_column":"SOURCE","table.cell_column":"EMAIL"},"collection_id":null,"result_metadata":[{"display_name":"EMAIL","field_ref":["field","EMAIL",{"base-type":"type/Text"}],"name":"EMAIL","base_type":"type/Text","effective_type":"type/Text","semantic_type":null,"fingerprint":{"global":{"distinct-count":2000,"nil%":0},"type":{"type/Text":{"percent-json":0,"percent-url":0,"percent-email":1,"percent-state":0,"average-length":24.181}}}},{"display_name":"SOURCE","field_ref":["field","SOURCE",{"base-type":"type/Text"}],"name":"SOURCE","base_type":"type/Text","effective_type":"type/Text","semantic_type":"type/Source","fingerprint":{"global":{"distinct-count":5,"nil%":0},"type":{"type/Text":{"percent-json":0,"percent-url":0,"percent-email":0,"percent-state":0,"average-length":7.3965}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PRODUCTS","dataset_query":{"type":"native","native":{"query":"select EAN, TITLE from `PRODUCTS`","template-tags":{}},"database":5},"display":"table","description":null,"visualization_settings":{"table.pivot_column":"TITLE","table.cell_column":"EAN"},"collection_id":null,"result_metadata":[{"display_name":"EAN","field_ref":["field","EAN",{"base-type":"type/Text"}],"name":"EAN","base_type":"type/Text","effective_type":"type/Text","semantic_type":null,"fingerprint":{"global":{"distinct-count":200,"nil%":0},"type":{"type/Text":{"percent-json":0,"percent-url":0,"percent-email":0,"percent-state":0,"average-length":13}}}},{"display_name":"TITLE","field_ref":["field","TITLE",{"base-type":"type/Text"}],"name":"TITLE","base_type":"type/Text","effective_type":"type/Text","semantic_type":"type/Title","fingerprint":{"global":{"distinct-count":199,"nil%":0},"type":{"type/Text":{"percent-json":0,"percent-url":0,"percent-email":0,"percent-state":0,"average-length":21.495}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PEOPLE MAP","dataset_query":{"type":"native","native":{"query":"SELECT LATITUDE, LONGITUDE FROM `PEOPLE`","template-tags":{}},"database":5},"display":"map","description":null,"visualization_settings":{"map.type":"pin","map.latitude_column":"LATITUDE","map.longitude_column":"LONGITUDE"},"collection_id":null,"result_metadata":[{"display_name":"LATITUDE","field_ref":["field","LATITUDE",{"base-type":"type/Float"}],"name":"LATITUDE","base_type":"type/Float","effective_type":"type/Float","semantic_type":"type/Latitude","fingerprint":{"global":{"distinct-count":1994,"nil%":0},"type":{"type/Number":{"min":25.8698057,"q1":35.32907147444435,"q3":43.81951642076601,"max":70.6355001,"sd":6.377141853799367,"avg":39.944154405}}}},{"display_name":"LONGITUDE","field_ref":["field","LONGITUDE",{"base-type":"type/Float"}],"name":"LONGITUDE","base_type":"type/Float","effective_type":"type/Float","semantic_type":"type/Longitude","fingerprint":{"global":{"distinct-count":1994,"nil%":0},"type":{"type/Number":{"min":-166.5425726,"q1":-102.03613753821496,"q3":-84.75747248668276,"max":-67.96735199999999,"sd":15.617312185969949,"avg":-95.44595759755}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"Q ORDERS","dataset_query":{"type":"native","native":{"query":"SELECT CREATED_AT, QUANTITY FROM `ORDERS`","template-tags":{}},"database":5},"display":"bar","description":null,"visualization_settings":{"graph.dimensions":["CREATED_AT"],"graph.metrics":["QUANTITY"]},"collection_id":null,"result_metadata":[{"display_name":"CREATED_AT","field_ref":["field","CREATED_AT",{"base-type":"type/DateTimeWithLocalTZ"}],"name":"CREATED_AT","base_type":"type/DateTimeWithLocalTZ","effective_type":"type/DateTimeWithLocalTZ","semantic_type":"type/CreationTimestamp","fingerprint":{"global":{"distinct-count":2000,"nil%":0},"type":{"type/DateTime":{"earliest":"2016-06-01T18:12:52Z","latest":"2020-04-19T14:07:15Z"}}}},{"display_name":"QUANTITY","field_ref":["field","QUANTITY",{"base-type":"type/Integer"}],"name":"QUANTITY","base_type":"type/Integer","effective_type":"type/Integer","semantic_type":"type/Quantity","fingerprint":{"global":{"distinct-count":27,"nil%":0},"type":{"type/Number":{"min":0,"q1":1.7680340018414042,"q3":5.078814523684541,"max":68,"sd":3.5020851003402265,"avg":3.6885}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"TOTAL ORDERS","dataset_query":{"type":"native","native":{"query":"SELECT CREATED_AT, TOTAL FROM `ORDERS`","template-tags":{}},"database":5},"display":"bar","description":null,"visualization_settings":{"graph.dimensions":["CREATED_AT"],"graph.metrics":["TOTAL"]},"collection_id":null,"result_metadata":[{"display_name":"CREATED_AT","field_ref":["field","CREATED_AT",{"base-type":"type/DateTimeWithLocalTZ"}],"name":"CREATED_AT","base_type":"type/DateTimeWithLocalTZ","effective_type":"type/DateTimeWithLocalTZ","semantic_type":"type/CreationTimestamp","fingerprint":{"global":{"distinct-count":2000,"nil%":0},"type":{"type/DateTime":{"earliest":"2016-06-01T18:12:52Z","latest":"2020-04-19T14:07:15Z"}}}},{"display_name":"TOTAL","field_ref":["field","TOTAL",{"base-type":"type/Float"}],"name":"TOTAL","base_type":"type/Float","effective_type":"type/Float","semantic_type":null,"fingerprint":{"global":{"distinct-count":2000,"nil%":0},"type":{"type/Number":{"min":15.968675813101619,"q1":52.72185432487288,"q3":111.76311166117706,"max":169.17982252162366,"sd":34.8393444705293,"avg":82.37024915648372}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-COUNT ORDERS","dataset_query":{"type":"native","native":{"query":"select count(*) from ORDERS","template-tags":{}},"database":3},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"count(*)","field_ref":["field","count(*)",{"base-type":"type/BigInteger"}],"name":"count(*)","base_type":"type/BigInteger","effective_type":"type/BigInteger","semantic_type":null,"fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":18760,"q1":18760,"q3":18760,"max":18760,"sd":null,"avg":18760}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-SUM TOTAL","dataset_query":{"type":"native","native":{"query":"select sum(total) from ORDERS","template-tags":{}},"database":3},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"sum(total)","field_ref":["field","sum(total)",{"base-type":"type/Float"}],"name":"sum(total)","base_type":"type/Float","effective_type":"type/Float","semantic_type":null,"fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":1595328.1251600615,"q1":1595328.1251600615,"q3":1595328.1251600615,"max":1595328.1251600615,"sd":null,"avg":1595328.1251600615}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-SUM SUBTOTAL","dataset_query":{"type":"native","native":{"query":"select sum(subtotal) from ORDERS","template-tags":{}},"database":3},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"sum(subtotal)","field_ref":["field","sum(subtotal)",{"base-type":"type/Float"}],"name":"sum(subtotal)","base_type":"type/Float","effective_type":"type/Float","semantic_type":null,"fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":1448188.1658779324,"q1":1448188.1658779324,"q3":1448188.1658779324,"max":1448188.1658779324,"sd":null,"avg":1448188.1658779324}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-SUM TAX","dataset_query":{"type":"native","native":{"query":"select sum(tax) from ORDERS","template-tags":{}},"database":3},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"sum(tax)","field_ref":["field","sum(tax)",{"base-type":"type/Float"}],"name":"sum(tax)","base_type":"type/Float","effective_type":"type/Float","semantic_type":null,"fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":72388.33999999962,"q1":72388.33999999962,"q3":72388.33999999962,"max":72388.33999999962,"sd":null,"avg":72388.33999999962}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-SUM DISCOUNT","dataset_query":{"type":"native","native":{"query":"select sum(discount) from ORDERS","template-tags":{}},"database":3},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"sum(discount)","field_ref":["field","sum(discount)",{"base-type":"type/Float"}],"name":"sum(discount)","base_type":"type/Float","effective_type":"type/Float","semantic_type":"type/Discount","fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":9954.822827272115,"q1":9954.822827272115,"q3":9954.822827272115,"max":9954.822827272115,"sd":null,"avg":9954.822827272115}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-SUM QUANTITY","dataset_query":{"type":"native","native":{"query":"select sum(QUANTITY) from ORDERS","template-tags":{}},"database":3},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"sum(QUANTITY)","field_ref":["field","sum(QUANTITY)",{"base-type":"type/Decimal"}],"name":"sum(QUANTITY)","base_type":"type/Decimal","effective_type":"type/Decimal","semantic_type":null,"fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":69540,"q1":69540,"q3":69540,"max":69540,"sd":null,"avg":69540}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-AVG REVIEWS","dataset_query":{"type":"native","native":{"query":"select AVG(rating) from REVIEWS","template-tags":{}},"database":3},"display":"scalar","description":null,"visualization_settings":{},"collection_id":null,"result_metadata":[{"display_name":"AVG(rating)","field_ref":["field","AVG(rating)",{"base-type":"type/Decimal"}],"name":"AVG(rating)","base_type":"type/Decimal","effective_type":"type/Decimal","semantic_type":"type/Score","fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":3.9874,"q1":3.9874,"q3":3.9874,"max":3.9874,"sd":null,"avg":3.9874}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-REVIEWS","dataset_query":{"type":"native","native":{"query":"select REVIEWER, RATING from REVIEWS","template-tags":{}},"database":3},"display":"table","description":null,"visualization_settings":{"table.pivot_column":"RATING","table.cell_column":"REVIEWER"},"collection_id":null,"result_metadata":[{"display_name":"REVIEWER","field_ref":["field","REVIEWER",{"base-type":"type/Text"}],"name":"REVIEWER","base_type":"type/Text","effective_type":"type/Text","semantic_type":null,"fingerprint":{"global":{"distinct-count":1076,"nil%":0},"type":{"type/Text":{"percent-json":0,"percent-url":0,"percent-email":0,"percent-state":0.001798561151079137,"average-length":9.972122302158274}}}},{"display_name":"RATING","field_ref":["field","RATING",{"base-type":"type/Integer"}],"name":"RATING","base_type":"type/Integer","effective_type":"type/Integer","semantic_type":"type/Score","fingerprint":{"global":{"distinct-count":5,"nil%":0},"type":{"type/Number":{"min":1,"q1":3.54744353181696,"q3":4.764807071650455,"max":5,"sd":1.0443899855660577,"avg":3.987410071942446}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-ORDERS","dataset_query":{"type":"native","native":{"query":"select TOTAL, QUANTITY from ORDERS","template-tags":{}},"database":3},"display":"table","description":null,"visualization_settings":{"table.pivot_column":"QUANTITY","table.cell_column":"TOTAL"},"collection_id":null,"result_metadata":[{"display_name":"TOTAL","field_ref":["field","TOTAL",{"base-type":"type/Float"}],"name":"TOTAL","base_type":"type/Float","effective_type":"type/Float","semantic_type":null,"fingerprint":{"global":{"distinct-count":2000,"nil%":0},"type":{"type/Number":{"min":15.968675813101619,"q1":52.72185432487288,"q3":111.76311166117706,"max":169.17982252162366,"sd":34.8393444705293,"avg":82.37024915648372}}}},{"display_name":"QUANTITY","field_ref":["field","QUANTITY",{"base-type":"type/Integer"}],"name":"QUANTITY","base_type":"type/Integer","effective_type":"type/Integer","semantic_type":"type/Quantity","fingerprint":{"global":{"distinct-count":27,"nil%":0},"type":{"type/Number":{"min":0,"q1":1.7680340018414042,"q3":5.078814523684541,"max":68,"sd":3.5020851003402265,"avg":3.6885}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-PEOPLE","dataset_query":{"type":"native","native":{"query":"select EMAIL, SOURCE from PEOPLE","template-tags":{}},"database":3},"display":"table","description":null,"visualization_settings":{"table.pivot_column":"SOURCE","table.cell_column":"EMAIL"},"collection_id":null,"result_metadata":[{"display_name":"EMAIL","field_ref":["field","EMAIL",{"base-type":"type/Text"}],"name":"EMAIL","base_type":"type/Text","effective_type":"type/Text","semantic_type":null,"fingerprint":{"global":{"distinct-count":2000,"nil%":0},"type":{"type/Text":{"percent-json":0,"percent-url":0,"percent-email":1,"percent-state":0,"average-length":24.181}}}},{"display_name":"SOURCE","field_ref":["field","SOURCE",{"base-type":"type/Text"}],"name":"SOURCE","base_type":"type/Text","effective_type":"type/Text","semantic_type":"type/Source","fingerprint":{"global":{"distinct-count":5,"nil%":0},"type":{"type/Text":{"percent-json":0,"percent-url":0,"percent-email":0,"percent-state":0,"average-length":7.3965}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-PRODUCTS","dataset_query":{"type":"native","native":{"query":"select EAN, TITLE from PRODUCTS","template-tags":{}},"database":3},"display":"table","description":null,"visualization_settings":{"table.pivot_column":"TITLE","table.cell_column":"EAN"},"collection_id":null,"result_metadata":[{"display_name":"EAN","field_ref":["field","EAN",{"base-type":"type/Text"}],"name":"EAN","base_type":"type/Text","effective_type":"type/Text","semantic_type":null,"fingerprint":{"global":{"distinct-count":200,"nil%":0},"type":{"type/Text":{"percent-json":0,"percent-url":0,"percent-email":0,"percent-state":0,"average-length":13}}}},{"display_name":"TITLE","field_ref":["field","TITLE",{"base-type":"type/Text"}],"name":"TITLE","base_type":"type/Text","effective_type":"type/Text","semantic_type":"type/Title","fingerprint":{"global":{"distinct-count":199,"nil%":0},"type":{"type/Text":{"percent-json":0,"percent-url":0,"percent-email":0,"percent-state":0,"average-length":21.495}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-PEOPLE MAP","dataset_query":{"type":"native","native":{"query":"SELECT LATITUDE, LONGITUDE FROM PEOPLE","template-tags":{}},"database":3},"display":"map","description":null,"visualization_settings":{"map.type":"pin","map.latitude_column":"LATITUDE","map.longitude_column":"LONGITUDE"},"collection_id":null,"result_metadata":[{"display_name":"LATITUDE","field_ref":["field","LATITUDE",{"base-type":"type/Float"}],"name":"LATITUDE","base_type":"type/Float","effective_type":"type/Float","semantic_type":"type/Latitude","fingerprint":{"global":{"distinct-count":1994,"nil%":0},"type":{"type/Number":{"min":25.8698057,"q1":35.32907147444435,"q3":43.81951642076601,"max":70.6355001,"sd":6.377141853799367,"avg":39.944154405}}}},{"display_name":"LONGITUDE","field_ref":["field","LONGITUDE",{"base-type":"type/Float"}],"name":"LONGITUDE","base_type":"type/Float","effective_type":"type/Float","semantic_type":"type/Longitude","fingerprint":{"global":{"distinct-count":1994,"nil%":0},"type":{"type/Number":{"min":-166.5425726,"q1":-102.03613753821496,"q3":-84.75747248668276,"max":-67.96735199999999,"sd":15.617312185969949,"avg":-95.44595759755}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-Q ORDERS","dataset_query":{"type":"native","native":{"query":"SELECT CREATED_AT, QUANTITY FROM ORDERS","template-tags":{}},"database":3},"display":"bar","description":null,"visualization_settings":{"graph.dimensions":["CREATED_AT"],"graph.metrics":["QUANTITY"]},"collection_id":null,"result_metadata":[{"display_name":"CREATED_AT","field_ref":["field","CREATED_AT",{"base-type":"type/DateTimeWithLocalTZ"}],"name":"CREATED_AT","base_type":"type/DateTimeWithLocalTZ","effective_type":"type/DateTimeWithLocalTZ","semantic_type":"type/CreationTimestamp","fingerprint":{"global":{"distinct-count":2000,"nil%":0},"type":{"type/DateTime":{"earliest":"2016-06-01T18:12:52Z","latest":"2020-04-19T14:07:15Z"}}}},{"display_name":"QUANTITY","field_ref":["field","QUANTITY",{"base-type":"type/Integer"}],"name":"QUANTITY","base_type":"type/Integer","effective_type":"type/Integer","semantic_type":"type/Quantity","fingerprint":{"global":{"distinct-count":27,"nil%":0},"type":{"type/Number":{"min":0,"q1":1.7680340018414042,"q3":5.078814523684541,"max":68,"sd":3.5020851003402265,"avg":3.6885}}}}]}' && \
curl -s -X POST http://$1/api/card -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"name":"PG-SSH-TOTAL ORDERS","dataset_query":{"type":"native","native":{"query":"SELECT CREATED_AT, TOTAL FROM ORDERS","template-tags":{}},"database":3},"display":"bar","description":null,"visualization_settings":{"graph.dimensions":["CREATED_AT"],"graph.metrics":["TOTAL"]},"collection_id":null,"result_metadata":[{"display_name":"CREATED_AT","field_ref":["field","CREATED_AT",{"base-type":"type/DateTimeWithLocalTZ"}],"name":"CREATED_AT","base_type":"type/DateTimeWithLocalTZ","effective_type":"type/DateTimeWithLocalTZ","semantic_type":"type/CreationTimestamp","fingerprint":{"global":{"distinct-count":2000,"nil%":0},"type":{"type/DateTime":{"earliest":"2016-06-01T18:12:52Z","latest":"2020-04-19T14:07:15Z"}}}},{"display_name":"TOTAL","field_ref":["field","TOTAL",{"base-type":"type/Float"}],"name":"TOTAL","base_type":"type/Float","effective_type":"type/Float","semantic_type":null,"fingerprint":{"global":{"distinct-count":2000,"nil%":0},"type":{"type/Number":{"min":15.968675813101619,"q1":52.72185432487288,"q3":111.76311166117706,"max":169.17982252162366,"sd":34.8393444705293,"avg":82.37024915648372}}}}]}';fi