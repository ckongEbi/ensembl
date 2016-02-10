#!/bin/bash

PPWD="${PWD}/.."
ENSDIR="${ENSDIR:-$PPWD}"

export PERL5LIB=$PWD/modules:$ENSDIR/bioperl-live:$ENSDIR/ensembl-test/modules:$ENSDIR/ensembl-variation/modules
export TEST_AUTHOR=$USER

if [ "$DB" = 'mysql' ]; then
    (cd modules/t && ln -sf MultiTestDB.conf.mysql MultiTestDB.conf)
elif [ "$DB" = 'sqlite' ]; then
    (cd modules/t && ln -sf MultiTestDB.conf.SQLite MultiTestDB.conf)
    SKIP_TESTS="--skip dbConnection.t,schema.t,schemaPatches.t,strainSlice.t"
else
    echo "Don't know about DB '$DB'"
    exit 1;
fi

echo "Running test suite"
if [ "$COVERALLS" = 'true' ]; then
  PERL5OPT='-MDevel::Cover=+ignore,bioperl,+ignore,ensembl-test,+ignore,ensembl-variation' perl $ENSDIR/../ensembl-test/scripts/runtests.pl -verbose modules/t $SKIP_TESTS
else
  perl $ENSDIR/../ensembl-test/scripts/runtests.pl modules/t $SKIP_TESTS
fi

rt=$?
if [ $rt -eq 0 ]; then
  if [ "$COVERALLS" = 'true' ]; then
    echo "Running Devel::Cover coveralls report"
    cover --nosummary -report coveralls
  fi
  exit $?
else
  exit $rt
fi
