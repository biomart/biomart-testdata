#!/bin/bash
# author Anthony Cros (anthony.cros@oicr.on.ca)
# quick and dirty way to check the input source column

# must be in testdata

TARGET_FILE=./icgc_target.tsv
SOURCE_FILE=./icgc_source.tsv
RELATION_FILE=./icgc_relations.tsv

DIR=/tmp/input_source
mkdir -p $DIR
rm $DIR/*

# we expect both to match
SOURCES=$DIR/sources # source table sets as described in icgc_source.file
SOURCES2=$DIR/sources2 # source table set as described in target table descriptions in icgc_targe.tsv

TARGETS=$DIR/targets

# isolate set of source tables based on the icgc_source.tsv file
cat $SOURCE_FILE | tr "\r" "\n" | tail -n+2 | awk -F$'\t' '{print $2}' | awk '{gsub(/"/,"")}1' | awk -F: '{print tolower($1)}' | sort -u > $SOURCES

# isolate set of target tables based on the icgc_target.tsv file
cat $TARGET_FILE | tr "\r" "\n" | tail -n+2 | awk -F$'\t' '{print $2}' | sort -u | awk -F: '{print $1}' > $TARGETS

# create one file per source table that contains the table's column (one per row)
for SOURCE_TABLE in `cat $SOURCES`; do
  cat $SOURCE_FILE | tr "\r" "\n" | tail -n+2 | awk -v IGNORECASE=1 -F$'\t' '$2~/'"$SOURCE_TABLE"':/' | awk '{gsub(/"/,"")}1' | awk -F$'\t' '{gsub(/:.+$/,"",$2);print $5}' > $DIR/$SOURCE_TABLE.cols
done

# create one file per target table such that:
#
# SNP mytable:mykey	my_target_col		my_source_table1/my_source_table2	R	int(1)	...
#
# becomes
#
# my_target_col		my_source_table1
# my_target_col		my_source_table2
#
for TARGET_TABLE in `cat $TARGETS`; do
  # they all have the trailing ":"
  cat $TARGET_FILE | tr "\r" "\n" | tail -n+2 | awk -F$'\t' '$2~/'"$TARGET_TABLE"':/' | awk -F$'\t' '{print $5}' | awk '!/^$/{gsub(/\//,"\n");print}' | sort -u > $DIR/$TARGET_TABLE.set
  cat $TARGET_FILE | tr "\r" "\n" | tail -n+2 | awk -F$'\t' '$2~/'"$TARGET_TABLE"':/' | awk -F$'\t' '$5!~/^$/{gsub(/\//,",",$5);print $5 "\t" $4}' | awk -F$'\t' '{gsub(/,/,"|" $2 "\n",$1);print $1 "|" $2}' > $DIR/$TARGET_TABLE.map
done

# make sure source tables described in the target table descriptions match the set of expected source tables (it does)
cat $DIR/*.set | sort -u > $SOURCES2
[ -z "`diff $SOURCES $SOURCES2`" ] || { echo ERROR; read; }
echo "ok :)"
cat $DIR/*.set | sort -u | wc -l # 38 = ~3x10 = 3 type of input (p, s, m) times 10 datasets (sample, ssm, sgv, ...)

# go through each target table and make sure that columns do belong to the specified source table
for TARGET_TABLE in `cat $TARGETS`; do
  for ROW in `cat $DIR/$TARGET_TABLE.map`; do
    SOURCE_TABLE=`echo $ROW | awk -F'|' '{print $1}'`
    COLUMN_NAME=`echo $ROW | awk -F'|' '{print $2}'`
    COUNT=`cat $DIR/$SOURCE_TABLE.cols | awk '/^'"$COLUMN_NAME"'$/' | wc -l`
    if [ $COUNT != 1 ]; then
      echo -e "$TARGET_TABLE\t$SOURCE_TABLE\t$COLUMN_NAME"
    fi
  done
done

