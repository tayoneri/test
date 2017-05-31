#!/bin/bash

SQL_CONF=/home/tayoneri/my.cnf
DB=HP
TABLE=words_test_2

function initStack() {
    stTop=0
}

function isEmpty() {
    if [ ${stTop} -eq 0 ]
    then
        return 0
    else
        return 1
    fi
}

function isFull() {
    if [ ${stTop} -ge 5 ]
    then
        return 0
    else
        return 1
    fi
}

function pushStack() {
    isFull
    if [ $? -eq 0 ]
    then
        return 1
    else
        stTop=$(( ${stTop} + 1 ))
        ST[${stTop}]=$1
        return
    fi
}

function popStack() {
    isEmpty
    if [ $? -eq 0 ]
    then
        return 1
    else
        stTop=$(( ${stTop} - 1 ))
        return ${ST[$(( ${stTop} + 1 ))]}
    fi
}

function replaceBlank() {
    i=0
    unset result_tmp
    unset result
    for result_tmp in "${result_arr[@]}"
    do
        if [ "${result_tmp}" == "　" ]
        then
            if [ $(($RANDOM % 10)) -lt 6 ]
            then
                result_tmp="___EOS___"
            fi
        fi
        result[${i}]="${result_tmp}"
        i=$((i + 1))
    done
}

while true
do
    initStack

    unset TMP
    unset OUTPUT
    unset result_arr
    
    KEY[0]="___BOS___"
    KEY[1]=""

    result_arr=($(mysql --defaults-extra-file=${SQL_CONF} -D${DB} -N -s -e 'select word_2 from words_test_2 where word_1="___BOS___";'))
    result_num=${#result_arr[@]}
    select_num=$(( $RANDOM % ${result_num} ))

    KEY[1]=${result_arr[select_num]}

    # 取得した文字列がいずれかのカッコならpush
    case "${KEY[1]}" in
        "「")   pushStack 101
                ;;
        "『")   pushStack 103
                ;;
        "（")   pushStack 105
                ;;
        "［")   pushStack 109
                ;;
        "”")   pushStack 107
                ;;
    esac

    OUTPUT="${KEY[1]}"

    while true
    do
        unset result_arr
        result_arr=($(mysql --defaults-extra-file=${SQL_CONF} -D${DB} -N -s -e "select word_3 from words_test_2 where word_1=\"${KEY[0]}\" and word_2=\"${KEY[1]}\";"))
        replaceBlank
        result_num=${#result[@]}

        if [ $result_num -eq 0 ]
        then
            echo Error:${KEY[0]}, ${KEY[1]}
            exit 1
        fi

        select_num=$(( $RANDOM % ${result_num} ))
        
        # カッコ対応判定
        case "${result[${select_num}]}" in
            *「*)
                pushStack 101
                KEY[2]=${result[${select_num}]}
                ;;
            *『*)
                pushStack 103
                KEY[2]=${result[${select_num}]}
                ;;
            *（*)
                pushStack 105
                KEY[2]=${result[${select_num}]}
                ;;
            *［*)
                pushStack 109
                KEY[2]=${result[${select_num}]}
                ;;
            *」*)
                popStack
                TMP=$?
                if [ ${TMP} -eq 101 ]
                then
                    KEY[2]=${result[${select_num}]}
                elif [ ${TMP} -ne 1 ]
                then
                    pushStack ${TMP}
                    continue 2
                else
                    continue 2
                fi
                ;;
            *』*)
                popStack
                TMP=$?
                if [ ${TMP} -eq 103 ]
                then
                    KEY[2]=${result[${select_num}]}
                elif [ ${TMP} -ne 1 ]
                then
                    pushStack ${TMP}
                    continue 2
                else
                    continue 2
                fi
                ;;
            *）*)
                popStack
                TMP=$?
                if [ ${TMP} -eq 105 ]
                then
                    KEY[2]=${result[${select_num}]}
                elif [ ${TMP} -ne 1 ]
                then
                    pushStack ${TMP}
                    continue 2
                else
                    continue 2
                fi
                ;;
            *］*)
                popStack
                TMP=$?
                if [ ${TMP} -eq 109 ]
                then
                    KEY[2]=${result[${select_num}]}
                elif [ ${TMP} -ne 1 ]
                then
                    pushStack ${TMP}
                    continue 2
                else
                    continue 2
                fi
                ;;
            "”")
                popStack
                TMP=$?
                if [ ${TMP} -eq 107 ]
                then
                    KEY[2]=${result[${select_num}]}
                elif [ ${TMP} -ne 1 ]
                then
                    pushStack ${TMP}
                    pushStack 107
                    KEY[2]=${result[${select_num}]}
                else
                    pushStack 107
                    KEY[2]=${result[${select_num}]}
                fi
                ;;
               *)
                KEY[2]=${result[${select_num}]}
                ;;
        esac
        
###        KEY[2]=${result[select_num]}

        if [ "${KEY[2]}" == "___EOS___" ]
        then
            break
        fi

        KEY[0]="${KEY[1]}"
        KEY[1]="${KEY[2]}"
        KEY[2]=$(echo ${KEY[2]} | sed -E 's/([A-Za-z]{1,})/ \1/g')
        OUTPUT="${OUTPUT}${KEY[2]}"

        if [ $(echo -n ${OUTPUT} | wc -m) -gt 140 ]
        then
            continue 2
        fi
    done
    
    LEN=$(echo -n ${OUTPUT} | wc -m)
    if [ ${LEN} -le 140 ]
    then
        isEmpty
        if [ $? -eq 0 ]
        then
            break
        else
            continue
        fi
    fi

done
OUTPUT=$(echo ${OUTPUT} | sed -E "s/([\-\!\?\('！？＆’（「『［　]) ([A-Za-z]{1,})/\1\2/g" | sed "s/’/'/g")

#OUTPUT=$(echo ${OUTPUT} | sed -E "s/([A-Za-z]{1,}) ([!\?\)'！？’）])/\1\2/g")
echo ${OUTPUT}  | bti --config /home/tayoneri/tsunkov_bot.bti
