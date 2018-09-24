#!/bin/sh

## Helper script to run fio tests and generate reports

DATA_DIR=./data
LOG_DIR=./logs
REPORT_DIR=./reports

# check if fio is installed
if ! type "fio" > /dev/null; then
    echo "ERROR: fio is not installed. Exiting"
    exit 1
fi

case $1 in
    128k)
        echo 'Only running 128k fio tests...'
        LS_CMD="*.128k.fio"
        ;;
    4k)
        echo 'Only running 4k fio tests...'
        LS_CMD="*.4k.fio"
        ;;
    douban)
        echo 'Only running douban fio tests...'
        LS_CMD="douban.*.fio"
        ;;
    all)
        echo 'Running all *.fio tests...'
        LS_CMD="*.fio"
        ;;
    *)
        echo "Running all *.fio tests..."
        LS_CMD="*.fio"
esac

FIO_BIN=fio
if [ "${2}x" != "x" ]; then
    FIO_BIN=${2}
fi

FIOS_LIST=$(ls ${LS_CMD})
NOW_EPOCH=$(date +"%s")

# create required directories
mkdir -p ${DATA_DIR}

if [ -d "${REPORT_DIR}" ]; then
    echo "Report directory exists, archiving using current timestamp: ${NOW_EPOCH}"
    mv ${REPORT_DIR} ${REPORT_DIR}_${NOW_EPOCH}
fi
mkdir -p ${REPORT_DIR}

if [ -d "${LOG_DIR}" ]; then
    echo "Log directory exists, archiving using current timestamp: ${NOW_EPOCH}"
    mv ${LOG_DIR} ${LOG_DIR}_${NOW_EPOCH}
fi
mkdir -p ${LOG_DIR}

# run all fios in sequential order
for i in $(echo ${FIOS_LIST} | tr " " "\n")
do
    echo -e "\nStarting fio test ${i}..."
    ${FIO_BIN} ./${i} --output ${REPORT_DIR}/${i}.out

    mv *.log ${LOG_DIR}/

    rm -f data/*   # delete created fio files after each run

    echo "Completed fio test ${i}."
done

# plot reports to svg
if type "fio_generate_plots" > /dev/null && type "gnuplot" > /dev/null; then

    echo "fio_generate_plots is installed generating svg reports based on fio logs"

    ( cd ${LOG_DIR} && rename 's/\.[0-9]+\.log/\.log/' ./* && fio_generate_plots "All-Ops" )

    mv ${LOG_DIR}/*.svg ${REPORT_DIR}/
fi
