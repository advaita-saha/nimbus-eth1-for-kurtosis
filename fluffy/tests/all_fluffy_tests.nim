# Nimbus
# Copyright (c) 2021-2024 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
#  * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{. warning[UnusedImport]:off .}

import
  ./test_portal_wire_protocol,
  ./state_network_tests/test_state_content_keys,
  ./state_network_tests/test_state_content_values,
  ./test_state_proof_verification,
  ./test_accumulator,
  ./test_history_network,
  ./test_content_db,
  ./test_discovery_rpc,
  ./test_beacon_chain_block_proof,
  ./test_beacon_chain_block_proof_capella,
  ./test_beacon_chain_historical_roots,
  ./test_beacon_chain_historical_summaries,
  ./beacon_network_tests/all_beacon_network_tests
