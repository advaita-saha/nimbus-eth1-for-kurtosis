# Nimbus
# Copyright (c) 2018-2019 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or
#    http://www.apache.org/licenses/LICENSE-2.0)
#  * MIT license ([LICENSE-MIT](LICENSE-MIT) or
#    http://opensource.org/licenses/MIT)
# at your option. This file may not be copied, modified, or distributed except
# according to those terms.

# Test cases from https://github.com/ethereum/EIPs/blob/master/EIPS/eip-225.md

import
  ../../nimbus/p2p/clique/clique_defs

type
  TesterVote* = object  ## VoterBlock represents a single block signed by a
                        ## particular account, where the account may or may not
                        ## have cast a Clique vote.
    signer*: string           ## Account that signed this particular block
    voted*: string            ## Optional value if the signer voted on
                              ## adding/removing ## someone
    auth*: bool               ## Whether the vote was to authorize (or
                              ## deauthorize)
    checkpoint*: seq[string]  ## List of authorized signers if this is an epoch
                              ## block
    newbatch*: bool

  TestSpecs* = object   ## Define the various voting scenarios to test
    id*: int                  ## Test id
    info*: string             ## Test description
    epoch*:   uint64          ## Number of blocks in an epoch (unset = 30000)
    signers*: seq[string]     ## Initial list of authorized signers in the
                              ## genesis
    votes*: seq[TesterVote]   ## Chain of signed blocks, potentially influencing
                              ## auths
    results*: seq[string]     ## Final list of authorized signers after all
                              ## blocks
    failure*: CliqueErrorType ## Failure if some block is invalid according to
                              ## the rules

const
  # Define the various voting scenarios to test
  voterSamples* = [
    # clique/snapshot_test.go(108): {
    TestSpecs(
      id:      1,
      info:    "Single signer, no votes cast",
      signers: @["A"],
      votes:   @[TesterVote(signer: "A")],
      results: @["A"]),

    TestSpecs(
      id:      2,
      info:    "Single signer, voting to add two others (only accept first, "&
               "second needs 2 votes)",
      signers: @["A"],
      votes:   @[TesterVote(signer: "A", voted: "B", auth: true),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "A", voted: "C", auth: true)],
      results: @["A", "B"]),

    TestSpecs(
      id:      3,
      info:    "Two signers, voting to add three others (only accept first " &
               "two, third needs 3 votes already)",
      signers: @["A", "B"],
      votes:   @[TesterVote(signer: "A", voted: "C", auth: true),
                 TesterVote(signer: "B", voted: "C", auth: true),
                 TesterVote(signer: "A", voted: "D", auth: true),
                 TesterVote(signer: "B", voted: "D", auth: true),
                 TesterVote(signer: "C"),
                 TesterVote(signer: "A", voted: "E", auth: true),
                 TesterVote(signer: "B", voted: "E", auth: true)],
      results: @["A", "B", "C", "D"]),

    TestSpecs(
      id:      4,
      info:    "Single signer, dropping itself (weird, but one less " &
               "cornercase by explicitly allowing this)",
      signers: @["A"],
      votes:   @[TesterVote(signer: "A", voted: "A")]),

    TestSpecs(
      id:      5,
      info:    "Two signers, actually needing mutual consent to drop either " &
               "of them (not fulfilled)",
      signers: @["A", "B"],
      votes:   @[TesterVote(signer: "A", voted: "B")],
      results: @["A", "B"]),

    TestSpecs(
      id:      6,
      info:    "Two signers, actually needing mutual consent to drop either " &
               "of them (fulfilled)",
      signers: @["A", "B"],
      votes:   @[TesterVote(signer: "A", voted: "B"),
                 TesterVote(signer: "B", voted: "B")],
      results: @["A"]),

    TestSpecs(
      id:      7,
      info:    "Three signers, two of them deciding to drop the third",
      signers: @["A", "B", "C"],
      votes:   @[TesterVote(signer: "A", voted: "C"),
                 TesterVote(signer: "B", voted: "C")],
      results: @["A", "B"]),

    TestSpecs(
      id:      8,
      info:    "Four signers, consensus of two not being enough to drop anyone",
      signers: @["A", "B", "C", "D"],
      votes:   @[TesterVote(signer: "A", voted: "C"),
                 TesterVote(signer: "B", voted: "C")],
      results: @["A", "B", "C", "D"]),

    TestSpecs(
      id:      9,
      info:    "Four signers, consensus of three already being enough to " &
               "drop someone",
      signers: @["A", "B", "C", "D"],
      votes:   @[TesterVote(signer: "A", voted: "D"),
                 TesterVote(signer: "B", voted: "D"),
                 TesterVote(signer: "C", voted: "D")],
      results: @["A", "B", "C"]),

    TestSpecs(
      id:      10,
      info:    "Authorizations are counted once per signer per target",
      signers: @["A", "B"],
      votes:   @[TesterVote(signer: "A", voted: "C", auth: true),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "A", voted: "C", auth: true),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "A", voted: "C", auth: true)],
      results: @["A", "B"]),

    TestSpecs(
      id:      11,
      info:    "Authorizing multiple accounts concurrently is permitted",
      signers: @["A", "B"],
      votes:   @[TesterVote(signer: "A", voted: "C", auth: true),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "A", voted: "D", auth: true),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "A"),
                 TesterVote(signer: "B", voted: "D", auth: true),
                 TesterVote(signer: "A"),
                 TesterVote(signer: "B", voted: "C", auth: true)],
      results: @["A", "B", "C", "D"]),

    TestSpecs(
      id:      12,
      info:    "Deauthorizations are counted once per signer per target",
      signers: @["A", "B"],
      votes:   @[TesterVote(signer: "A", voted: "B"),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "A", voted: "B"),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "A", voted: "B")],
      results: @["A", "B"]),

    TestSpecs(
      id:      13,
      info:    "Deauthorizing multiple accounts concurrently is permitted",
      signers: @["A", "B", "C", "D"],
      votes:   @[TesterVote(signer: "A", voted: "C"),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "C"),
                 TesterVote(signer: "A", voted: "D"),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "C"),
                 TesterVote(signer: "A"),
                 TesterVote(signer: "B", voted: "D"),
                 TesterVote(signer: "C", voted: "D"),
                 TesterVote(signer: "A"),
                 TesterVote(signer: "B", voted: "C")],
      results: @["A", "B"]),

    TestSpecs(
      id:      14,
      info:    "Votes from deauthorized signers are discarded immediately " &
               "(deauth votes)",
      signers: @["A", "B", "C"],
      votes:   @[TesterVote(signer: "C", voted: "B"),
                 TesterVote(signer: "A", voted: "C"),
                 TesterVote(signer: "B", voted: "C"),
                 TesterVote(signer: "A", voted: "B")],
      results: @["A", "B"]),

    TestSpecs(
      id:      15,
      info:    "Votes from deauthorized signers are discarded immediately " &
               "(auth votes)",
      signers: @["A", "B", "C"],
      votes:   @[TesterVote(signer: "C", voted: "D", auth: true),
                 TesterVote(signer: "A", voted: "C"),
                 TesterVote(signer: "B", voted: "C"),
                 TesterVote(signer: "A", voted: "D", auth: true)],
      results: @["A", "B"]),

    TestSpecs(
      id:      16,
      info:    "Cascading changes are not allowed, only the account being " &
               "voted on may change",
      signers: @["A", "B", "C", "D"],
      votes:   @[TesterVote(signer: "A", voted: "C"),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "C"),
                 TesterVote(signer: "A", voted: "D"),
                 TesterVote(signer: "B", voted: "C"),
                 TesterVote(signer: "C"),
                 TesterVote(signer: "A"),
                 TesterVote(signer: "B", voted: "D"),
                 TesterVote(signer: "C", voted: "D")],
      results: @["A", "B", "C"]),

    TestSpecs(
      id:      17,
      info:    "Changes reaching consensus out of bounds (via a deauth) " &
               "execute on touch",
      signers: @["A", "B", "C", "D"],
      votes:   @[TesterVote(signer: "A", voted: "C"),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "C"),
                 TesterVote(signer: "A", voted: "D"),
                 TesterVote(signer: "B", voted: "C"),
                 TesterVote(signer: "C"),
                 TesterVote(signer: "A"),
                 TesterVote(signer: "B", voted: "D"),
                 TesterVote(signer: "C", voted: "D"),
                 TesterVote(signer: "A"),
                 TesterVote(signer: "C", voted: "C", auth: true)],
      results: @["A", "B"]),

    TestSpecs(
      id:      18,
      info:    "Changes reaching consensus out of bounds (via a deauth) " &
               "may go out of consensus on first touch",
      signers: @["A", "B", "C", "D"],
      votes:   @[TesterVote(signer: "A", voted: "C"),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "C"),
                 TesterVote(signer: "A", voted: "D"),
                 TesterVote(signer: "B", voted: "C"),
                 TesterVote(signer: "C"),
                 TesterVote(signer: "A"),
                 TesterVote(signer: "B", voted: "D"),
                 TesterVote(signer: "C", voted: "D"),
                 TesterVote(signer: "A"),
                 TesterVote(signer: "B", voted: "C", auth: true)],
      results: @["A", "B", "C"]),

    TestSpecs(
      id:      19,
      info:    "Ensure that pending votes don't survive authorization status " &
               "changes. This corner case can only appear if a signer is " &
               "quickly added, removed and then readded (or the inverse), " &
               "while one of the original voters dropped. If a past vote is " &
               "left cached in the system somewhere, this will interfere " &
               "with the final signer outcome.",
      signers: @["A", "B", "C", "D", "E"],
      votes:   @[
        # Authorize F, 3 votes needed
        TesterVote(signer: "A", voted: "F", auth: true),
        TesterVote(signer: "B", voted: "F", auth: true),
        TesterVote(signer: "C", voted: "F", auth: true),

        # Deauthorize F, 4 votes needed (leave A's previous vote "unchanged")
        TesterVote(signer: "D", voted: "F"),
        TesterVote(signer: "E", voted: "F"),
        TesterVote(signer: "B", voted: "F"),
        TesterVote(signer: "C", voted: "F"),

        # Almost authorize F, 2/3 votes needed
        TesterVote(signer: "D", voted: "F", auth: true),
        TesterVote(signer: "E", voted: "F", auth: true),

        # Deauthorize A, 3 votes needed
        TesterVote(signer: "B", voted: "A"),
        TesterVote(signer: "C", voted: "A"),
        TesterVote(signer: "D", voted: "A"),

        # Finish authorizing F, 3/3 votes needed
        TesterVote(signer: "B", voted: "F", auth: true)],
      results: @["B", "C", "D", "E", "F"]),

    TestSpecs(
      id:      20,
      info:    "Epoch transitions reset all votes to allow chain checkpointing",
      epoch:   3,
      signers: @["A", "B"],
      votes:   @[TesterVote(signer: "A", voted: "C", auth: true),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "A", checkpoint: @["A", "B"]),
                 TesterVote(signer: "B", voted: "C", auth: true)],
      results: @["A", "B"]),

    TestSpecs(
      id:      21,
      info:    "An unauthorized signer should not be able to sign blocks",
      signers: @["A"],
      votes:   @[TesterVote(signer: "B")],
      failure: errUnauthorizedSigner),

    TestSpecs(
      id:      22,
      info:    "An authorized signer that signed recenty should not be able " &
               "to sign again",
      signers: @["A", "B"],
      votes:   @[TesterVote(signer: "A"),
                 TesterVote(signer: "A")],
      failure: errRecentlySigned),

    TestSpecs(
      id:      23,
      info:    "Recent signatures should not reset on checkpoint blocks " &
               "imported in a batch " &
               "(https://github.com/ethereum/go-ethereum/issues/17593). "&
               "Whilst this seems overly specific and weird, it was a "&
               "Rinkeby consensus split.",
      epoch:   3,
      signers: @["A", "B", "C"],
      votes:   @[TesterVote(signer: "A"),
                 TesterVote(signer: "B"),
                 TesterVote(signer: "A", checkpoint: @["A", "B", "C"]),
                 TesterVote(signer: "A", newbatch: true)],
      failure: errRecentlySigned)]

static:
  # For convenience, make sure that IDs are increasing
  for n in 1 ..< voterSamples.len:
    if voterSamples[n-1].id < voterSamples[n].id:
      continue
    echo "voterSamples[", n, "] == ", voterSamples[n].id, " expected ",
      voterSamples[n-1].id + 1, " or greater"
    doAssert voterSamples[n-1].id < voterSamples[n].id

# End