# Nimbus
# Copyright (c) 2023-2024 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or
#    http://www.apache.org/licenses/LICENSE-2.0)
#  * MIT license ([LICENSE-MIT](LICENSE-MIT) or
#    http://opensource.org/licenses/MIT)
# at your option. This file may not be copied, modified, or distributed except
# according to those terms.

## This module automatically pulls in the persistent backend libraries at the
## linking stage (e.g. `rocksdb`) which can be avoided for pure memory DB
## applications by importing `db/code_db/memory_only` (rather than
## `db/core_db/persistent`.)
##
## The right way to use this file on a conditional mode is to import it as in
## ::
##   import ./path/to/core_db
##   when ..condition..
##     import ./path/to/core_db/persistent
##
{.push raises: [].}

import
  ../aristo,
  ./memory_only,
  base_iterators_persistent,
  ./backend/[aristo_rocksdb, legacy_rocksdb]

export
  memory_only,
  base_iterators_persistent,
  toRocksStoreRef

proc newCoreDbRef*(
    dbType: static[CoreDbType];      # Database type symbol
    path: string;                    # Storage path for database
    chainId: ChainId;
      ): CoreDbRef =
  ## Constructor for persistent type DB
  ##
  ## Note: Using legacy notation `newCoreDbRef()` rather than
  ## `CoreDbRef.init()` because of compiler coughing.
  when dbType == LegacyDbPersistent:
    let res = newLegacyPersistentCoreDbRef path

  elif dbType == AristoDbRocks:
    let res = newAristoRocksDbCoreDbRef path

  else:
    {.error: "Unsupported dbType for persistent newCoreDbRef()".}

  res.chainId = chainId
  res

proc newCoreDbRef*(
    dbType: static[CoreDbType];      # Database type symbol
    path: string;                    # Storage path for database
    chainId: ChainId;
    qidLayout: QidLayoutRef;         # Optional for `Aristo`, ignored by others
      ): CoreDbRef =
  ## Constructor for persistent type DB
  ##
  ## Note: Using legacy notation `newCoreDbRef()` rather than
  ## `CoreDbRef.init()` because of compiler coughing.
  when dbType == AristoDbRocks:
    let res = newAristoRocksDbCoreDbRef(path, qlr)

  else:
    {.error: "Unsupported dbType for persistent newCoreDbRef()" &
            " with qidLayout argument".}

  res.chainId = chainId
  res

# End
