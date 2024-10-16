source(output(
		Id as integer,
		Name as string,
		Age as integer,
		City as string
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false) ~> scdSourceTable
source(output(
		surrKey as integer,
		id as integer,
		name as string,
		age as integer,
		city as string,
		isActive as integer
	),
	allowSchemaDrift: true,
	validateSchema: false,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> SqlDbTableSrc
scdSourceTable derive(isActive = 1) ~> addedisActiveCol
SqlDbTableSrc select(mapColumn(
		SQL_surrKey = surrKey,
		SQL_id = id,
		SQL_name = name,
		SQL_age = age,
		SQL_city = city,
		SQL_isActive = isActive
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> selectafterSQL
scdSourceTable, selectafterSQL lookup(Id == SQL_id,
	multiple: true,
	broadcast: 'auto')~> lookupintoSQL
lookupintoSQL filter(!isNull(SQL_id)) ~> filterlookupTable
filterlookupTable select(mapColumn(
		SQL_surrKey,
		SQL_id,
		SQL_name,
		SQL_age,
		SQL_city,
		SQL_isActive
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> select1
select1 derive(SQL_isActive = 0) ~> updateIsActiveas0
updateIsActiveas0 alterRow(updateIf(1==1)) ~> alterRowisActive
addedisActiveCol sink(allowSchemaDrift: true,
	validateSchema: false,
	input(
		surrKey as integer,
		id as integer,
		name as string,
		age as integer,
		city as string,
		isActive as integer
	),
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	format: 'table',
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	saveOrder: 2,
	errorHandlingOption: 'stopOnFirstError',
	mapColumn(
		id = Id,
		name = Name,
		age = Age,
		city = City,
		isActive
	)) ~> InsertScdSink2
alterRowisActive sink(allowSchemaDrift: true,
	validateSchema: false,
	input(
		surrKey as integer,
		id as integer,
		name as string,
		age as integer,
		city as string,
		isActive as integer
	),
	deletable:false,
	insertable:false,
	updateable:true,
	upsertable:false,
	keys:['surrKey'],
	format: 'table',
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	saveOrder: 1,
	errorHandlingOption: 'stopOnFirstError',
	mapColumn(
		surrKey = SQL_surrKey,
		id = SQL_id,
		name = SQL_name,
		age = SQL_age,
		city = SQL_city,
		isActive = SQL_isActive
	)) ~> sink1Update