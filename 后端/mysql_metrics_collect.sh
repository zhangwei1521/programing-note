performanceIndex() {
    mysqlName=$1
    host=$2
    port=$3
    username=$4
    password=$5
    indexList=$6

    #单位：秒
    connectTimeout=5
	readTimeout=5

    tempFile="$$.temp"
    errFile="$$.err"
    flag=0
    deadLockKpiStr=""
    schemaKpiStr=""
    slowSQLKpiStr=""
    multiValueKpiStr=""
    OLD_IFS="$IFS"
    IFS=";"
    arr=($indexList)
    IFS="$OLD_IFS"
    exist=$(which mysql 2>/dev/null)
    if [ ! -n "$exist" ]; then
        echo "mysql 命令不存在"
        return
    fi

    echo "{"
    echo "\"mysqlName\":\"$mysqlName\","
    echo "\"mysqlHostIp\":\"$host\","
    echo "\"mysqlPort\":\"$port\","
    echo "\"kpi\":{"
    echo "\"active\":\"true\""

    errContent=""
    for index in ${arr[@]}; do
        switchFun $index
    done

    echo "}"

    if [ -n "$errContent" ]; then
        echo ",\"errContent\":\"$errContent\""
    fi

    if [ $flag -eq 0 ]; then
        echo "}"
    else
        echo ",\"multiValueKpi\": ["
        if [ "$deadLockKpiStr" != "" ]; then
            multiValueKpiStr="${multiValueKpiStr}{\"label\": \"mysqlDeadlockCheck\","
            multiValueKpiStr="${multiValueKpiStr}\"key\":\"id\","
            multiValueKpiStr="${multiValueKpiStr}\"kpis\":["
            deadLockKpiStr=${deadLockKpiStr%?}
            multiValueKpiStr="${multiValueKpiStr}${deadLockKpiStr}"
            multiValueKpiStr="${multiValueKpiStr}]},"
        fi
        if [ "$schemaKpiStr" != "" ]; then
            multiValueKpiStr="${multiValueKpiStr}{\"label\": \"schemaInfo\","
            multiValueKpiStr="${multiValueKpiStr}\"key\":\"schema\","
            multiValueKpiStr="${multiValueKpiStr}\"kpis\":["
            schemaKpiStr=${schemaKpiStr%?}
            multiValueKpiStr="${multiValueKpiStr}${schemaKpiStr}"
            multiValueKpiStr="${multiValueKpiStr}]},"
        fi
        if [ "$slowSQLKpiStr" != "" ]; then
            multiValueKpiStr="${multiValueKpiStr}{\"label\": \"top10SlowSQL\","
            multiValueKpiStr="${multiValueKpiStr}\"key\":\"seq\","
            multiValueKpiStr="${multiValueKpiStr}\"kpis\":["
            slowSQLKpiStr=${slowSQLKpiStr%?}
            multiValueKpiStr="${multiValueKpiStr}${slowSQLKpiStr}"
            multiValueKpiStr="${multiValueKpiStr}]},"
        fi
        multiValueKpiStr=${multiValueKpiStr%?}
        echo $multiValueKpiStr
        echo "]"
        echo "}"
    fi

    if [ -f "$tempFile" ]; then
        rm $tempFile
    fi

    if [ -f "$errFile" ]; then
        rm $errFile
    fi
}

switchFun() {
    case "$1" in
    "mysqlKeyBufferReadHitRate")
        collectKeyBufferReadHitRate
        ;;
    "mysqlKeyBufferWriteHitRate")
        collectKeyBufferWriteHitRate
        ;;
    "mysqlInnodbBufferHitRate")
        collectInnodbBufferHitRate
        ;;
    "mysqlThreadCacheHitRate")
        collectThreadCacheHitRate
        ;;
    "mysqlTableLocksWaited")
        collectTableLocksWaited
        ;;
    "mysqlQueryCacheHitRate")
        collectQueryCacheHitRate
        ;;
    "mysqlCreatedTmpDiskTables")
        collectCreatedTmpDiskTables
        ;;
    "mysqlCreatedTmpFiles")
        collectCreatedTmpFiles
        ;;
    "mysqlCreatedTmpTables")
        collectCreatedTmpTables
        ;;
    "mysqlSlowLaunchTime")
        collectSlowLaunchTime
        ;;
    "mysqlOpenFiles")
        collectOpenFiles
        ;;
    "mysqlSlaveIOState")
        collectSlaveIOState
        ;;
    "mysqlSlaveSQLRunning")
        collectSlaveSQLRunning
        ;;
    "mysqlSecondsBehindMaster")
        collectSecondsBehindMaster
        ;;
    "mysqlDeadlockCheck")
        collectDeadlockCheck
        ;;
    "mysqlVersion")
        collectVersion
        ;;
    "mysqlStartTime")
        collectStartTime
        ;;
    "mysqlAccessStatus")
        collectAccessStatus
        ;;
    "mysqlConnectedThreads")
        collectThreadConnected
        ;;
    "mysqlRunningThreads")
        collectThreadRunning
        ;;
    "mysqlCachedThreads")
        collectThreadCached
        ;;
    "mysqlReceivedBytes")
        collectReceivedBytes
        ;;
    "mysqlSentBytes")
        collectSentBytes
        ;;
    "mysqlQPS")
        collectQPS
        ;;
    "mysqlTPS")
        collectTPS
        ;;
    "mysqlOpenTableNum")
        collectOpenTableNum
        ;;
    "mysqlTableOpenCache")
        collectTableOpenCache
        ;;
    "mysqlOpenFilesLimit")
        collectOpenFilesLimit
        ;;
    "mysqlDMLPS")
        collectDMLPS
        ;;
    "mysqlInnodbDataRead")
        collectInnodbDataRead
        ;;
    "mysqlInnodbDataWritten")
        collectInnodbDataWritten
        ;;
    "mysqlInnodbRowsRead")
        collectInnodbRowsRead
        ;;
    "mysqlInnodbRowsInsert")
        collectInnodbRowsInsert
        ;;
    "mysqlInnodbRowsDelete")
        collectInnodbRowsDelete
        ;;
    "mysqlInnodbRowsUpdate")
        collectInnodbRowsUpdate
        ;;
    "mysqlAbortedClients")
        collectAbortedClients
        ;;
    "mysqlAbortedConnects")
        collectAbortedConnects
        ;;
    "mysqlBinlogDiskUsed")
        collectBinlogDiskUsed
        ;;
    "mysqlSchemaInfo")
        collectSchemasInfo
        ;;
    "top10SlowSQL")
        collectTop10SlowSQL
        ;;
    "") ;;

    esac
}

collectKeyBufferReadHitRate() {
    #mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
    mysql -h $host -P $port -u $username -p$password --connect-timeout=$connectTimeout  <<EOF >$tempFile 2>$errFile
        set @@session.wait_timeout=$readTimeout;
        show global status like 'key_read%';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    keyReadRequests=$(cat $tempFile | grep "^Key_read_requests" | awk '{print $2}')
    KeyReads=$(cat $tempFile | grep "^Key_reads" | awk '{print $2}')
    if [ $keyReadRequests -eq 0 ]; then
        keyBufferReadHitRate=0
    else
        keyBufferReadHitRate=$(echo "$KeyReads $keyReadRequests" | awk '{printf "%.2f", 100-(($1*100)/$2)}')
    fi
    echo ",\"mysqlKeyBufferReadHitRate\":\"$keyBufferReadHitRate\""
}

collectKeyBufferWriteHitRate() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'Key_blocks_unused%';
        show variables like 'key%';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    keyBlocksUnused=$(cat $tempFile | grep "^Key_blocks_unused" | awk '{print $2}')
    keyBufferSize=$(cat $tempFile | grep "^key_buffer_size" | awk '{print $2}')
    keyCacheBlockSize=$(cat $tempFile | grep "^key_cache_block_size" | awk '{print $2}')
    if [ $keyBufferSize -eq 0 ]; then
        keyBufferWriteHitRate=0
    else
        keyBufferWriteHitRate=$(echo "$keyBlocksUnused $keyCacheBlockSize $keyBufferSize" | awk '{printf "%.2f", 100-(($1*$2)*100/$3)}')
    fi
    echo ",\"mysqlKeyBufferWriteHitRate\":\"$keyBufferWriteHitRate\""
}

collectInnodbBufferHitRate() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show  global status like 'Innodb_buffer_pool_read_%';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    innodbBufferPoolReads=$(cat $tempFile | grep "^Innodb_buffer_pool_reads" | awk '{print $2}')
    innodbBufferPoolReadRequests=$(cat $tempFile | grep "^Innodb_buffer_pool_read_requests" | awk '{print $2}')
    if [ $innodbBufferPoolReadRequests -eq 0 ]; then
        innodbBufferHitRate=0
    else
        innodbBufferHitRate=$(echo "$innodbBufferPoolReads $innodbBufferPoolReadRequests" | awk '{printf "%.2f", (1-$1/$2)*100}')
    fi
    echo ",\"mysqlInnodbBufferHitRate\":\"$innodbBufferHitRate\""
}

collectThreadCacheHitRate() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'thread%';
        show global status like 'connections%';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    threadsCreated=$(cat $tempFile | grep "^Threads_created" | awk '{print $2}')
    connections=$(cat $tempFile | grep "^Connections" | awk '{print $2}')
    if [ $connections -eq 0 ]; then
        threadCacheHitRate=0
    else
        threadCacheHitRate=$(echo "$connections $threadsCreated" | awk '{printf "%.2f", ($1-$2)/$1*100}')
    fi
    echo ",\"mysqlThreadCacheHitRate\":\"$threadCacheHitRate\""
}

collectTableLocksWaited() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'table_locks%';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    tableLocksWaited=$(cat $tempFile | grep "^Table_locks_waited" | awk '{print $2}')
    echo ",\"mysqlTableLocksWaited\":\"$tableLocksWaited\""
}

collectQueryCacheHitRate() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show variables like '%query_cache%';
        show global status like 'QCache%';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    queryCacheType=$(cat $tempFile | grep "^query_cache_type" | awk '{print $2}')
    queryCacheHitRate=0
    if [ "$queryCacheType" != "OFF" ]; then
        qcacheHits=$(cat $tempFile | grep "^Qcache_hits" | awk '{print $2}')
        qcacheInserts=$(cat $tempFile | grep "^Qcache_inserts" | awk '{print $2}')
        if [ $qcacheHits -ne 0 ]; then
            queryCacheHitRate=$(echo "$qcacheHits $qcacheInserts" | awk '{printf "%.2f", $1/($1+$2)*100}')
        fi
    fi
    echo ",\"mysqlQueryCacheHitRate\":\"$queryCacheHitRate\""
}

collectCreatedTmpDiskTables() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'created_tmp%';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    createdTmpDiskTables=$(cat $tempFile | grep "^Created_tmp_disk_tables" | awk '{print $2}')
    echo ",\"mysqlCreatedTmpDiskTables\":\"$createdTmpDiskTables\""
}

collectCreatedTmpFiles() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'created_tmp%';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    createdTmpFiles=$(cat $tempFile | grep "^Created_tmp_files" | awk '{print $2}')
    echo ",\"mysqlCreatedTmpFiles\":\"$createdTmpFiles\""
}

collectCreatedTmpTables() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'created_tmp%';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    createdTmpTables=$(cat $tempFile | grep "^Created_tmp_tables" | awk '{print $2}')
    echo ",\"mysqlCreatedTmpTables\":\"$createdTmpTables\""
}

collectSlowLaunchTime() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show variables like 'slow%';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    slowLaunchTime=$(cat $tempFile | grep "^slow_launch_time" | awk '{print $2}')
    echo ",\"mysqlSlowLaunchTime\":\"$slowLaunchTime\""
}

collectOpenFiles() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'open%';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    openFiles=$(cat $tempFile | grep "^Open_files" | awk '{print $2}')
    echo ",\"mysqlOpenFiles\":\"$openFiles\""
}

collectSlaveIOState() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show slave status \G
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    num=$(cat $tempFile | wc -l)
    if [ $num -eq 0 ]; then
        slaveIOState=""
    else
        slaveIOState=$(cat $tempFile | grep "Slave_IO_State" | awk -F ': ' '{print $2}')
    fi
    echo ",\"mysqlSlaveIOState\":\"$slaveIOState\""
}

collectSlaveSQLRunning() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show slave status \G
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    num=$(cat $tempFile | wc -l)
    if [ $num -eq 0 ]; then
        slaveSQLRunning=""
    else
        slaveSQLRunning=$(cat $tempFile | grep -w "Slave_SQL_Running" | awk '{print $2}')
    fi
    echo ",\"mysqlSlaveSQLRunning\":\"$slaveSQLRunning\""
}

collectSecondsBehindMaster() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show slave status \G
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    num=$(cat $tempFile | wc -l)
    if [ $num -eq 0 ]; then
        secondsBehindMaster=0
    else
        secondsBehindMaster=$(cat $tempFile | grep "Seconds_Behind_Master" | awk '{print $2}')
        if [ $secondsBehindMaster == "NULL" ]; then
            secondsBehindMaster=0
        fi
    fi
    echo ",\"mysqlSecondsBehindMaster\":\"$secondsBehindMaster\""
}

collectDeadlockCheck() {
    mysql -h $host -P $port -u $username -p$password -s <<EOF >$tempFile 2>$errFile
        select id,user,host,db,"|",info,"|",state from information_schema.processlist WHERE state='Waiting for table metadata lock';
        exit
EOF
    flag=1
    while read line; do
        check_id=$(echo $line | awk '{print $1}')
        check_user=$(echo $line | awk '{print $2}')
        check_host=$(echo $line | awk '{print $3}')
        check_db=$(echo $line | awk '{print $4}')
        check_info=$(echo $line | awk -F "|" '{print $2}' | awk '$1=$1')
        check_state=$(echo $line | awk -F "|" '{print $3}' | awk '$1=$1')
        deadLockKpiStr="$deadLockKpiStr{"
        deadLockKpiStr="$deadLockKpiStr\"id\": \"$check_id\","
        deadLockKpiStr="$deadLockKpiStr\"user\": \"$check_user\","
        deadLockKpiStr="$deadLockKpiStr\"host\": \"$check_host\","
        deadLockKpiStr="$deadLockKpiStr\"db\": \"$check_db\","
        deadLockKpiStr="$deadLockKpiStr\"state\": \"$check_state\","
        deadLockKpiStr="$deadLockKpiStr\"info\": \"$check_info\""
        deadLockKpiStr="$deadLockKpiStr},"
    done <$tempFile
}

collectVersion() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
                        show global variables like 'version';
                        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    version=$(cat $tempFile | grep "version" | awk '{print $2}')

    echo ",\"mysqlVersion\":\"$version\""
}

collectStartTime() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
                        show global status where variable_name='Uptime';
                        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    upSeconds=$(cat $tempFile | grep "Uptime" | awk '{print $2}')

    nowtimestamp=$(date +%s)

    uptimestamp=$(expr $nowtimestamp - $upSeconds)

    startTime=$(date --date="@${uptimestamp}")
    echo ",\"mysqlStartTime\":\"$startTime\""
}

collectAccessStatus() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
                exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    if [ -n "$errContentTmp" ]; then
        echo ",\"mysqlAccessStatus\":\"未连通\""
    else
        echo ",\"mysqlAccessStatus\":\"已连通\""
    fi

}

collectThreadConnected() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
                        show global status where variable_name='Threads_connected';
                        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    connectedThreads=$(cat $tempFile | grep "Threads_connected" | awk '{print $2}')

    echo ",\"mysqlConnectedThreads\":\"$connectedThreads\""
}

collectThreadRunning() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
                        show global status where variable_name='Threads_running';
                        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    runningThreads=$(cat $tempFile | grep "Threads_running" | awk '{print $2}')

    echo ",\"mysqlRunningThreads\":\"$runningThreads\""
}

collectThreadCached() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
                        show global status where variable_name='Threads_cached';
                        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    cachedThreads=$(cat $tempFile | grep "Threads_cached" | awk '{print $2}')

    echo ",\"mysqlCachedThreads\":\"$cachedThreads\""
}

collectReceivedBytes() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
                        show global status where variable_name like 'Bytes_received';
                        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    receivedBytes=$(cat $tempFile | grep "Bytes_received" | awk '{print $2}')

    echo ",\"mysqlReceivedBytes\":\"$receivedBytes\""
}

collectSentBytes() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
                        show global status where variable_name like 'Bytes_sent';
                        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    sentBytes=$(cat $tempFile | grep "Bytes_sent" | awk '{print $2}')

    echo ",\"mysqlSentBytes\":\"$sentBytes\""
}

collectQPS() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        SHOW GLOBAL STATUS LIKE 'Questions';
        SHOW GLOBAL STATUS LIKE 'Uptime';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    questionsBegin=$(cat $tempFile | grep "^Questions" | awk '{print $2}')
    upTimeBegin=$(cat $tempFile | grep "^Uptime" | awk '{print $2}')

    sleep 60

    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        SHOW GLOBAL STATUS LIKE 'Questions';
        SHOW GLOBAL STATUS LIKE 'Uptime';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    questionsEnd=$(cat $tempFile | grep "^Questions" | awk '{print $2}')
    upTimeEnd=$(cat $tempFile | grep "^Uptime" | awk '{print $2}')

    A=$(expr $questionsEnd - $questionsBegin)
    B=$(expr $upTimeEnd - $upTimeBegin)

    if [ $B -eq 0 ]; then
        QPS=0
    else
        QPS=$(echo "$A $B" | awk '{printf "%.0f", $1 / $2}')
    fi

    echo ",\"mysqlQPS\":\"$QPS\""
}

collectTPS() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        SHOW GLOBAL STATUS LIKE 'Com_commit';
        SHOW GLOBAL STATUS LIKE 'Com_rollback';
        SHOW GLOBAL STATUS LIKE 'Uptime';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    commitBegin=$(cat $tempFile | grep "^Com_commit" | awk '{print $2}')
    rollbackBegin=$(cat $tempFile | grep "^Com_rollback" | awk '{print $2}')
    upTimeBegin=$(cat $tempFile | grep "^Uptime" | awk '{print $2}')

    sleep 60

    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        SHOW GLOBAL STATUS LIKE 'Com_commit';
        SHOW GLOBAL STATUS LIKE 'Com_rollback';
        SHOW GLOBAL STATUS LIKE 'Uptime';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    commitEnd=$(cat $tempFile | grep "^Com_commit" | awk '{print $2}')
    rollbackEnd=$(cat $tempFile | grep "^Com_rollback" | awk '{print $2}')
    upTimeEnd=$(cat $tempFile | grep "^Uptime" | awk '{print $2}')

    A=$(expr $commitEnd - $commitBegin)
    B=$(expr $rollbackEnd - $rollbackBegin)
    C=$(expr $upTimeEnd - $upTimeBegin)

    if [ $C -eq 0 ]; then
        TPS=0
    else
        TPS=$(echo "$A $B $C" | awk '{printf "%.0f", ($1 + $2) / $3}')
    fi

    echo ",\"mysqlTPS\":\"$TPS\""
}

collectOpenTableNum() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'Open_tables';
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    openTableNum=$(cat $tempFile | grep "^Open_tables" | awk '{print $2}')

    if [ ! -n "$openTableNum" ]; then
        openTableNum=0
    fi

    echo ",\"mysqlOpenTableNum\":\"$openTableNum\""
}

collectTableOpenCache() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global variables like 'table_open_cache';
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    tableOpenCache=$(cat $tempFile | grep "^table_open_cache" | awk '{print $2}')

    echo ",\"mysqlTableOpenCache\":\"$tableOpenCache\""
}

collectOpenFilesLimit() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global variables like 'open_files_limit';
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    openFilesLimit=$(cat $tempFile | grep "^open_files_limit" | awk '{print $2}')
    echo ",\"mysqlOpenFilesLimit\":\"$openFilesLimit\""
}

collectDMLPS() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        SHOW GLOBAL STATUS LIKE 'Com_insert';
        SHOW GLOBAL STATUS LIKE 'Com_delete';
        SHOW GLOBAL STATUS LIKE 'Com_update';
                SHOW GLOBAL STATUS LIKE 'Com_select';
                SHOW GLOBAL STATUS LIKE 'Uptime';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    insertBegin=$(cat $tempFile | grep "^Com_insert" | awk '{print $2}')
    deleteBegin=$(cat $tempFile | grep "^Com_delete" | awk '{print $2}')
    updateBegin=$(cat $tempFile | grep "^Com_update" | awk '{print $2}')
    selectBegin=$(cat $tempFile | grep "^Com_select" | awk '{print $2}')
    upTimeBegin=$(cat $tempFile | grep "^Uptime" | awk '{print $2}')
    dmlBegin=$(expr $insertBegin + $deleteBegin + $updateBegin + $selectBegin)

    sleep 60

    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        SHOW GLOBAL STATUS LIKE 'Com_insert';
        SHOW GLOBAL STATUS LIKE 'Com_delete';
        SHOW GLOBAL STATUS LIKE 'Com_update';
                SHOW GLOBAL STATUS LIKE 'Com_select';
                SHOW GLOBAL STATUS LIKE 'Uptime';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    insertEnd=$(cat $tempFile | grep "^Com_insert" | awk '{print $2}')
    deleteEnd=$(cat $tempFile | grep "^Com_delete" | awk '{print $2}')
    updateEnd=$(cat $tempFile | grep "^Com_update" | awk '{print $2}')
    selectEnd=$(cat $tempFile | grep "^Com_select" | awk '{print $2}')
    upTimeEnd=$(cat $tempFile | grep "^Uptime" | awk '{print $2}')
    dmlEnd=$(expr $insertEnd + $deleteEnd + $updateEnd + $selectEnd)

    A=$(expr $dmlEnd - $dmlBegin)
    B=$(expr $upTimeEnd - $upTimeBegin)

    if [ $C -eq 0 ]; then
        DMLPS=0
    else
        DMLPS=$(echo "$A $B" | awk '{printf "%.0f", $1 / $2}')
    fi

    echo ",\"mysqlDMLPS\":\"$DMLPS\""
}

collectInnodbDataRead() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'Innodb_data_read';
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    innodbDataRead=$(cat $tempFile | grep "^Innodb_data_read" | awk '{print $2}')
    echo ",\"mysqlInnodbDataRead\":\"$innodbDataRead\""
}

collectInnodbDataWritten() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'Innodb_data_written';
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    innodbDataWritten=$(cat $tempFile | grep "^Innodb_data_written" | awk '{print $2}')
    echo ",\"mysqlInnodbDataWritten\":\"$innodbDataWritten\""
}

collectInnodbRowsRead() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'Innodb_rows_read';
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    innodbRowsRead=$(cat $tempFile | grep "^Innodb_rows_read" | awk '{print $2}')
    echo ",\"mysqlInnodbRowsRead\":\"$innodbRowsRead\""
}

collectInnodbRowsInsert() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'Innodb_rows_inserted';
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    innodbRowsInsert=$(cat $tempFile | grep "^Innodb_rows_inserted" | awk '{print $2}')
    echo ",\"mysqlInnodbRowsInsert\":\"$innodbRowsInsert\""
}

collectInnodbRowsDelete() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'Innodb_rows_deleted';
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    innodbRowsDelete=$(cat $tempFile | grep "^Innodb_rows_deleted" | awk '{print $2}')
    echo ",\"mysqlInnodbRowsDelete\":\"$innodbRowsDelete\""
}

collectInnodbRowsUpdate() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'Innodb_rows_updated';
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    innodbRowsUpdate=$(cat $tempFile | grep "^Innodb_rows_updated" | awk '{print $2}')
    echo ",\"mysqlInnodbRowsUpdate\":\"$innodbRowsUpdate\""
}

collectAbortedClients() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'Aborted_clients';
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    abortedClients=$(cat $tempFile | grep "Aborted_clients" | awk '{print $2}')
    echo ",\"mysqlAbortedClients\":\"$abortedClients\""
}

collectAbortedConnects() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global status like 'Aborted_connects';
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    abortedConnects=$(cat $tempFile | grep "Aborted_connects" | awk '{print $2}')
    echo ",\"mysqlAbortedConnects\":\"$abortedConnects\""
}

collectBinlogDiskUsed() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global variables like 'log_bin';
        show variables like 'log_bin_basename';
        exit
EOF

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    binlogPath=$(cat $$.temp | grep "^log_bin" | awk '{print $2}')
    if [ ! -n "$binlogPath" ] || [ "$binlogPath" == "OFF" ]; then
        binlogDiskUsed=0
    else
        binlogPath=$(cat $tempFile | grep "^log_bin_basename" | awk '{print $2}')
        temp=${binlogPath##*/}
        binlogPath=$(echo $binlogPath | sed "s/\/$temp$//")
        binlogDiskUsed=$(du -sm $binlogPath 2>$errFile | awk '{print $1}')
    fi

    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    echo ",\"mysqlBinlogDiskUsed\":\"$binlogDiskUsed\""
}

collectSchemasInfo() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        select table_schema as 'schema',
                        (sum(truncate(data_length/1024/1024, 2))+sum(truncate(index_length/1024/1024, 2))) as 'schemaSize(MB)'
                from information_schema.tables
                group by table_schema
                order by sum(data_length) desc, sum(index_length) desc;
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    flag=1
    while read line; do
        headLine=$(echo "$line" | grep "schemaSize(MB)")
        if [ -z "$headLine" ]; then
            schema=$(echo $line | awk '{print $1}')
            schemaSize=$(echo $line | awk '{print $2}')
            schemaKpiStr="$schemaKpiStr{"
            schemaKpiStr="$schemaKpiStr\"schema\": \"$schema\","
            schemaKpiStr="$schemaKpiStr\"schemaSize\": \"$schemaSize\""
            schemaKpiStr="$schemaKpiStr},"
        fi
    done <$tempFile
}

collectTop10SlowSQL() {
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        show global variables like 'slow_query_log';
                show global variables like 'log_output';
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi

    slowQueryLog=$(cat $tempFile | grep "slow_query_log" | awk '$1=="slow_query_log" {print $2}')
    if [ "$slowQueryLog" != "ON" ]; then
        errContent="${errContent},slow_query_log=OFF"
        return
    fi
    logOutput=$(cat $tempFile | grep "log_output" | awk '{print $2}')
    logOutputUseTable=$(echo $logOutput | grep "TABLE")
    if [ -z $logOutputUseTable ]; then
        errContent="${errContent},log_output not table"
        return
    fi
    flag=1
    mysql -h $host -P $port -u $username -p$password <<EOF >$tempFile 2>$errFile
        SELECT (@rownum :=@rownum + 1) AS row,a.* FROM ( 
                        SELECT count(sql_text) as count,avg(query_time) AS query_time, avg(lock_time) AS lock_time, 
                                avg(rows_sent) AS rows_sent, avg(rows_examined) AS rows_examined, sql_text 
                        FROM mysql.slow_log 
                        WHERE start_time > date_sub(now(), INTERVAL 1 MONTH) 
                        GROUP BY sql_text 
                ) a ,(SELECT @rownum := 0) b
                ORDER BY a.query_time DESC 
                LIMIT 0, 10;
        exit
EOF
    errContentTmp=$(cat $errFile | grep -iv "Warning" | awk '{printf $0";"}')
    errContent=$errContent$errContentTmp
    if [ -n "$errContentTmp" ]; then
        return
    fi
    while read line; do
        headLine=$(echo "$line" | awk '{print $1}' | grep "row")
        if [ -z "$headLine" ]; then
            sqlSeq=$(echo $line | awk '{print $1}')
            sqlCount=$(echo $line | awk '{print $2}')
            sqlTimeAvg=$(echo $line | awk '{print $3}')
            sqlRowsSentAvg=$(echo $line | awk '{print $5}')
            sqlRowsExamindedAvg=$(echo $line | awk '{print $6}')
            #sqlText=`echo $line | awk '{print $7}'`
            sqlText=$(echo $line | awk '{x=7;while(x<=NF){printf "%s ", $x;x++;}}' | sed 's/ +/ /g')

            slowSQLKpiStr="$slowSQLKpiStr{"
            slowSQLKpiStr="$slowSQLKpiStr\"seq\": \"$sqlSeq\","
            slowSQLKpiStr="$slowSQLKpiStr\"sqlCount\": \"$sqlCount\","
            slowSQLKpiStr="$slowSQLKpiStr\"sqlTimeAvg\": \"$sqlTimeAvg\","
            slowSQLKpiStr="$slowSQLKpiStr\"sqlRowsSentAvg\": \"$sqlRowsSentAvg\","
            slowSQLKpiStr="$slowSQLKpiStr\"sqlRowsExamindedAvg\": \"$sqlRowsExamindedAvg\","
            slowSQLKpiStr="$slowSQLKpiStr\"sqlText\": \"$sqlText\""
            slowSQLKpiStr="$slowSQLKpiStr},"
        fi
    done <$tempFile
}

performanceIndex "mysql_localhost" "127.0.0.1" "3306" "root" "root" "mysqlVersion;mysqlStartTime;mysqlOpenFiles;mysqlConnectedThreads;mysqlSchemaInfo"
