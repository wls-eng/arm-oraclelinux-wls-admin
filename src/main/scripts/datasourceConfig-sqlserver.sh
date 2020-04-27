export oracleHome=$1
export wlsAdminHost=$2
export wlsAdminPort=$3
export wlsUserName=$4
export wlsPassword=$5
export jdbcDataSourceName=$6
export dsConnectionURL=$7
export dsUser=$8
export dsPassword=$9
export wlsClusterName=${10-cluster1}
export wlsAdminURL=$wlsAdminHost:$wlsAdminPort
export hostName=`hostname`

#Function to output message to StdErr
function echo_stderr ()
{
    echo "$@" >&2
}

#Function to display usage message
function usage()
{
  echo_stderr "./configDatasource.sh <oracleHome> <wlsAdminHost> <wlsAdminPort> <wlsUserName> <wlsPassword> <jdbcDataSourceName> <dsConnectionURL> <dsUser> <dsPassword> <wlsClusterName> "  
}

function validateInput()
{

   if [ -z "$oracleHome" ];
   then
       echo _stderr "Please provide oracleHome"
       exit 1
   fi

   if [ -z "$wlsAdminHost" ];
   then
       echo _stderr "Please provide WeblogicServer hostname"
       exit 1
   fi

   if [ -z "$wlsAdminPort" ];
   then
       echo _stderr "Please provide Weblogic admin port"
       exit 1
   fi

   if [ -z "$wlsUserName" ];
   then
       echo _stderr "Please provide Weblogic username"
       exit 1
   fi

   if [ -z "$wlsPassword" ];
   then
       echo _stderr "Please provide Weblogic password"
       exit 1
   fi

   if [ -z "$jdbcDataSourceName" ];
   then
       echo _stderr "Please provide JDBC datasource name to be configured"
       exit 1
   fi

   if [ -z "$dsConnectionURL" ];
   then
        echo _stderr "Please provide Azure SQL Database URL in the format 'jdbc:oracle:thin:@<db host name>:<db port>/<database name>'"
        exit 1
   fi

   if [ -z "$dsUser" ];
   then
       echo _stderr "Please provide Azure SQL Database user name"
       exit 1
   fi

   if [ -z "$dsPassword" ];
   then
       echo _stderr "Please provide Azure SQL Database password"
       exit 1
   fi

   if [ -z "$wlsClusterName" ];
   then
       echo _stderr "Please provide Weblogic target cluster name"
       exit 1
   fi

}

function createJDBCSource_model()
{
echo "Creating JDBC data source with name $jdbcDataSourceName"
cat <<EOF >create_datasource.py
connect('$wlsUserName','$wlsPassword','t3://$wlsAdminURL')
edit("$hostName")
startEdit()
cd('/')
try:
  cmo.createJDBCSystemResource('$jdbcDataSourceName')
  cd('/JDBCSystemResources/$jdbcDataSourceName/JDBCResource/$jdbcDataSourceName')
  cmo.setName('$jdbcDataSourceName')
  cd('/JDBCSystemResources/$jdbcDataSourceName/JDBCResource/$jdbcDataSourceName/JDBCDataSourceParams/$jdbcDataSourceName')
  set('JNDINames',jarray.array([String('$jdbcDataSourceName')], String))
  cd('/JDBCSystemResources/$jdbcDataSourceName/JDBCResource/$jdbcDataSourceName')
  cmo.setDatasourceType('GENERIC')
  cd('/JDBCSystemResources/$jdbcDataSourceName/JDBCResource/$jdbcDataSourceName/JDBCDriverParams/$jdbcDataSourceName')
  cmo.setUrl('$dsConnectionURL')
  cmo.setDriverName('com.microsoft.sqlserver.jdbc.SQLServerDriver')
  cmo.setPassword('$dsPassword')
  cd('/JDBCSystemResources/$jdbcDataSourceName/JDBCResource/$jdbcDataSourceName/JDBCConnectionPoolParams/$jdbcDataSourceName')
  cmo.setTestTableName('SQL ISVALID\r\n\r\n\r\n\r\n')
  cd('/JDBCSystemResources/$jdbcDataSourceName/JDBCResource/$jdbcDataSourceName/JDBCDriverParams/$jdbcDataSourceName/Properties/$jdbcDataSourceName')
  cmo.createProperty('user')
  cd('/JDBCSystemResources/$jdbcDataSourceName/JDBCResource/$jdbcDataSourceName/JDBCDriverParams/$jdbcDataSourceName/Properties/$jdbcDataSourceName/Properties/user')
  cmo.setValue('$dsUser')
  cd('/JDBCSystemResources/$jdbcDataSourceName/JDBCResource/$jdbcDataSourceName/JDBCDataSourceParams/$jdbcDataSourceName')
  cmo.setGlobalTransactionsProtocol('EmulateTwoPhaseCommit')
  cd('/JDBCSystemResources/$jdbcDataSourceName')
  set('Targets',jarray.array([ObjectName('com.bea:Name=$wlsClusterName,Type=Cluster')], ObjectName))
  save()
  resolve()
  activate()
except Exception, e:
  print "Already datasource with name $jdbcDataSourceName exists"
destroyEditSession("$hostName",force = true)
disconnect()
EOF
}

if [ $# -lt 9 ]
then
    usage
    exit 1
fi

validateInput
createJDBCSource_model

. $oracleHome/oracle_common/common/bin/setWlstEnv.sh


java $WLST_ARGS weblogic.WLST create_datasource.py $wlsUserName $wlsPassword $wlsAdminURL $jdbcDataSourceName $dsConnectionURL $dsUser $dsPassword $wlsClusterName


